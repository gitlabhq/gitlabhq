#!/usr/bin/env bash

# Fetches the GitLab EE activation code from 1Password and activates the
# license via a Rails runner against the cluster's toolbox pod.
#
# Intended to run as a Caproni edit_mode_start lifecycle hook so that the
# license is activated automatically each time `caproni run` starts.
#
# Activation is opt-in: without CAPRONI_ACTIVATE_LICENSE=1 the script does
# nothing at all. Once opted in, a missing `op` CLI is skipped with a warning,
# but every other failure -- a locked vault, an unavailable toolbox pod, a
# Rails error -- is fatal and blocks `caproni run`. Set
# CAPRONI_ACTIVATE_LICENSE=0 to skip activation instead.
#
# Prerequisites:
# - Cluster is up and toolbox pod is healthy
# - `.gitlab/caproni/setup.sh` was performed (config files in place)
# - 1Password CLI (`op`) installed and app integration enabled

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONOLITH_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

CONFIG="$MONOLITH_DIR/.gitlab/caproni/.mirrord/activate-license.json"
TARGET_DEPLOYMENT="deploy/gitlab-toolbox"
TARGET="$TARGET_DEPLOYMENT/container/toolbox"
NAMESPACE="${GITLAB_NAMESPACE:-gitlab}"
RAILS_ENV="${RAILS_ENV:-development}"

ONEPASSWORD_ITEM="GitLab_self_managed_ultimate_Duo_enterprise"
ONEPASSWORD_VAULT="Engineering"
ONEPASSWORD_FIELD="activation_code"

info()  { echo "[INFO] $*"; }
warn()  { echo "[WARN] $*" >&2; }
err()   { echo "[ERROR] $*" >&2; }

# ------------------------------------------------------------------
# 0. Opt-in check — skip unless CAPRONI_ACTIVATE_LICENSE=1
# ------------------------------------------------------------------
if [[ "${CAPRONI_ACTIVATE_LICENSE:-0}" != "1" ]]; then
  info "Skipping license activation (set CAPRONI_ACTIVATE_LICENSE=1 in .mise.toml [env] to enable)."
  exit 0
fi

# ------------------------------------------------------------------
# 1. Check op CLI availability and authentication
# ------------------------------------------------------------------
# No `op` at all means no 1Password to fetch a code from, and nobody in that
# position wants a license -- warn and continue. Every later failure is fatal,
# because from here on 1Password is present and the problem is fixable.
if ! command -v op &>/dev/null; then
  warn "'op' CLI not found — skipping license activation."
  warn "Install it via 'mise install' and enable 1Password app integration to activate automatically."
  exit 0
fi

if ! op whoami </dev/null &>/dev/null; then
  err "1Password CLI is not authenticated — cannot fetch the license activation code."
  err "Run 'op signin' (or unlock the 1Password app), then re-run 'caproni run'."
  err "To start unlicensed instead, set CAPRONI_ACTIVATE_LICENSE=0, or activate manually at:"
  err "  http://gitlab.caproni.test/admin/subscription"
  exit 1
fi

# ------------------------------------------------------------------
# 2. Fetch activation code from 1Password
# ------------------------------------------------------------------
info "Fetching license activation code from 1Password..."
activation_code=""

if ! activation_code=$(op item get "${ONEPASSWORD_ITEM}" \
    --vault "${ONEPASSWORD_VAULT}" \
    --fields "${ONEPASSWORD_FIELD}" 2>&1); then
  err "Failed to fetch activation code from 1Password: ${activation_code}"
  err "Check your access to the '${ONEPASSWORD_ITEM}' item in the '${ONEPASSWORD_VAULT}' vault,"
  err "or set CAPRONI_ACTIVATE_LICENSE=0 to skip license activation."
  exit 1
fi

if [[ -z "${activation_code}" ]]; then
  err "1Password returned an empty '${ONEPASSWORD_FIELD}' field for '${ONEPASSWORD_ITEM}'."
  err "Fix the item, or set CAPRONI_ACTIVATE_LICENSE=0 to skip license activation."
  exit 1
fi

# ------------------------------------------------------------------
# 3. Wait for toolbox pod and activate license via Rails runner
# ------------------------------------------------------------------
info "Waiting for toolbox pod..."
if ! kubectl wait -n "${NAMESPACE}" --for=condition=Available "${TARGET_DEPLOYMENT}" --timeout=60s; then
  err "${TARGET_DEPLOYMENT} in namespace ${NAMESPACE} did not become available within 60s."
  err "Bring the cluster up with 'caproni up' before starting edit mode."
  exit 1
fi

info "Activating license via Rails runner..."
set +e
output=$(ACTIVATION_CODE="${activation_code}" mirrord exec \
  --config-file "${CONFIG}" \
  --target "${TARGET}" \
  --target-namespace "${NAMESPACE}" \
  -- bash -c "cd '${MONOLITH_DIR}' && mise exec -- bundle exec rails runner -e '${RAILS_ENV}' -" <<'RUBY'
begin
  activation_code = ENV.fetch('ACTIVATION_CODE')

  if License.current&.cloud?
    puts "✓ License already active (#{License.current.plan}, expires #{License.current.expires_at})"

    add_on = GitlabSubscriptions::AddOn.find_or_create_by!(name: 'duo_enterprise') do |a|
      a.description = 'GitLab Duo Enterprise'
    end
    add_on_purchase = GitlabSubscriptions::AddOnPurchase.find_or_create_by!(add_on: add_on) do |p|
      p.quantity        = 1
      p.started_at      = License.current.starts_at || Date.current
      p.expires_on      = License.current.expires_at
      p.purchase_xid    = "caproni-auto-#{Time.now.to_i}"
      p.organization_id = Organizations::Organization.first&.id
    end
    root_user = User.find_by_username('root')
    if root_user
      GitlabSubscriptions::UserAddOnAssignment.find_or_create_by!(
        add_on_purchase: add_on_purchase, user: root_user
      )
    end

    puts "ALREADY_ACTIVE"
    exit 0
  end

  license = License.create!(data: activation_code.gsub("\\n", "\n"), cloud: true)
  begin
    Gitlab::SeatLinkData.new(refresh_token: true).sync
  rescue => e
    warn "SeatLinkData sync failed (non-fatal): #{e.message}" if ENV['DEBUG']
  end

  add_on = GitlabSubscriptions::AddOn.find_or_create_by!(name: 'duo_enterprise') do |a|
    a.description = 'GitLab Duo Enterprise'
  end
  add_on_purchase = GitlabSubscriptions::AddOnPurchase.find_or_create_by!(add_on: add_on) do |p|
      p.quantity        = 1
      p.started_at      = license.starts_at || Date.current
      p.expires_on      = license.expires_at
      p.purchase_xid    = "caproni-auto-#{Time.now.to_i}"
      p.organization_id = Organizations::Organization.first&.id
    end
  root_user = User.find_by_username('root')
  GitlabSubscriptions::UserAddOnAssignment.find_or_create_by!(
    add_on_purchase: add_on_purchase, user: root_user
  ) if root_user

  puts "✓ License activated: #{license.plan}, expires #{license.expires_at}"
  puts "SUCCESS"

rescue StandardError => e
  puts "ERROR: #{e.message}"
  puts e.backtrace.first(3).join("\n") if ENV['DEBUG']
  exit(License.current&.cloud? ? 0 : 1)
end
RUBY
)
exit_code=$?
set -e
echo "${output}"

# Anything other than an explicit ALREADY_ACTIVE/SUCCESS marker is a failure,
# including a zero exit with no marker: the Rails runner's rescue block prints
# ERROR and exits 0 whenever a cloud license exists at the time it is reached.
if echo "${output}" | grep -qE "ALREADY_ACTIVE|SUCCESS"; then
  info "License activation complete."
else
  err "License activation failed (rails runner exit ${exit_code}, no success marker); see the output above."
  err "Activate manually at: http://gitlab.caproni.test/admin/subscription"
  err "To let 'caproni run' proceed unlicensed, set CAPRONI_ACTIVATE_LICENSE=0."
  exit 1
fi

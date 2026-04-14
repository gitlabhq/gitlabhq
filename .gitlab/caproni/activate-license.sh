#!/usr/bin/env bash

# Fetches the GitLab EE activation code from 1Password and activates the
# license via a Rails runner against the cluster's toolbox pod.
#
# Intended to run as a Caproni edit_mode_start lifecycle hook so that the
# license is activated automatically each time `caproni run` starts.
#
# If 1Password CLI is unavailable or not authenticated the script exits
# successfully with a warning so it does not block `caproni run`.
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
if ! command -v op &>/dev/null; then
  warn "'op' CLI not found — skipping license activation."
  warn "Install via 'mise install' and enable 1Password app integration to activate automatically."
  exit 0
fi

if ! op whoami </dev/null &>/dev/null; then
  warn "1Password CLI is not authenticated — skipping license activation."
  warn "Run 'op signin' and re-run 'caproni run' to activate automatically, or activate manually at:"
  warn "  http://gitlab.caproni.test/admin/subscription"
  exit 0
fi

# ------------------------------------------------------------------
# 2. Fetch activation code from 1Password
# ------------------------------------------------------------------
info "Fetching license activation code from 1Password..."
activation_code=""

if ! activation_code=$(op item get "${ONEPASSWORD_ITEM}" \
    --vault "${ONEPASSWORD_VAULT}" \
    --fields "${ONEPASSWORD_FIELD}" 2>&1); then
  warn "Failed to fetch activation code from 1Password: ${activation_code}"
  warn "Activate manually at: http://gitlab.caproni.test/admin/subscription"
  exit 0
fi

if [[ -z "${activation_code}" ]]; then
  warn "Retrieved empty activation code from 1Password — skipping."
  exit 0
fi

# ------------------------------------------------------------------
# 3. Wait for toolbox pod and activate license via Rails runner
# ------------------------------------------------------------------
info "Waiting for toolbox pod..."
kubectl wait -n "${NAMESPACE}" --for=condition=Available "${TARGET_DEPLOYMENT}" --timeout=60s

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

if echo "${output}" | grep -qE "ALREADY_ACTIVE|SUCCESS"; then
  info "License activation complete."
elif [[ ${exit_code} -ne 0 ]]; then
  warn "License activation failed — activate manually at: http://gitlab.caproni.test/admin/subscription"
  exit 0  # don't block caproni run
fi

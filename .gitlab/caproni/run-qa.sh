#!/usr/bin/env bash
# Run GitLab QA tests against the local caproni cluster.
#
# Usage:
#   .gitlab/caproni/run-qa.sh                          # smoke tests (default)
#   .gitlab/caproni/run-qa.sh Test::Instance::All      # full suite
#   .gitlab/caproni/run-qa.sh Test::Instance::Smoke -- --tag ~slow   # pass extra rspec options
#
# Environment overrides:
#   QA_GITLAB_URL        (default: http://gitlab.caproni.test)
#   GITLAB_ADMIN_PASSWORD  (default: fetched from the cluster secret)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QA_DIR="${SCRIPT_DIR}/../../qa"

# Resolve admin password from cluster unless already set
if [[ -z "${GITLAB_ADMIN_PASSWORD:-}" ]]; then
  GITLAB_ADMIN_PASSWORD="$(
    caproni kubectl get secret -n gitlab gitlab-gitlab-initial-root-password \
      -o jsonpath='{.data.password}' | base64 -d
  )"
fi

export QA_GITLAB_URL="${QA_GITLAB_URL:-http://gitlab.caproni.test}"
export GITLAB_ADMIN_USERNAME="${GITLAB_ADMIN_USERNAME:-root}"
export GITLAB_ADMIN_PASSWORD

SCENARIO="${1:-Test::Instance::Smoke}"
shift 2>/dev/null || true  # remaining args forwarded to rspec

echo "Running QA scenario: ${SCENARIO}"
echo "Target: ${QA_GITLAB_URL}"
echo

cd "${QA_DIR}"

mise exec -- bash -c "bundle check || bundle install"
mise exec -- bundle exec bin/qa "${SCENARIO}" "${QA_GITLAB_URL}" "$@"

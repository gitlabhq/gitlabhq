#!/usr/bin/env bash
set -euo pipefail

MINIMUM_VERSION="v8.20"
SCRIPT_NAME=$(basename "$0")
HOOK_TYPE="${1:-}"

if ! command -v gitleaks &>/dev/null; then
  cat >&2 <<EOF
WARNING: gitleaks is not installed. Skipping secrets detection.
Please install at least version v$MINIMUM_VERSION using "asdf install" or see:
https://gitlab.com/gitlab-com/gl-security/security-research/gitleaks-endpoint-installer.
EOF
  exit 0
fi

# Check whether config/gitleaks-local.toml is up-to-date or if it needs to be regenerated
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$SCRIPT_DIR/.."
GENERATOR_SCRIPT="$REPO_ROOT/scripts/generate-gitleaks-local-config.sh"
LOCAL_CONFIG="$REPO_ROOT/config/gitleaks-local.toml"

if [ -f "$GENERATOR_SCRIPT" ]; then
  EXPECTED=$("$GENERATOR_SCRIPT" --dry-run 2>/dev/null || true)
  ACTUAL=$(cat "$LOCAL_CONFIG" 2>/dev/null || true)
  if [ "$EXPECTED" != "$ACTUAL" ]; then
    cat >&2 <<EOF
ERROR: config/gitleaks-local.toml is out of date.
Please run: scripts/generate-gitleaks-local-config.sh
EOF
    exit 1
  fi
fi

if [ -z "$HOOK_TYPE" ]; then
  cat >&2 <<EOF
ERROR: Hook type argument is required.
Usage: ./$SCRIPT_NAME [pre-commit|pre-push]
Please specify 'pre-commit' or 'pre-push' as the argument.
EOF
  exit 1
fi

# Run gitleaks
if [ "$HOOK_TYPE" == "pre-commit" ]; then
  gitleaks git -c config/gitleaks-local.toml --pre-commit --staged --no-banner --redact --verbose
elif [ "$HOOK_TYPE" == "pre-push" ]; then
  BASE_COMMIT=$(git merge-base origin/master HEAD)
  gitleaks git -c config/gitleaks-local.toml --log-opts="$BASE_COMMIT..HEAD" --no-banner --redact --verbose
else
  cat >&2 <<EOF
ERROR: Unsupported hook type '$HOOK_TYPE'.
Usage: ./$SCRIPT_NAME [pre-commit|pre-push]
EOF
  exit 1
fi

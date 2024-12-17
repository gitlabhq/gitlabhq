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

if [ -z "$HOOK_TYPE" ]; then
  cat >&2 <<EOF
ERROR: Hook type argument is required.
Usage: ./$SCRIPT_NAME [pre-commit|pre-push]
Please specify 'pre-commit' or 'pre-push' as the argument.
EOF
  exit 1
fi

if [ "$HOOK_TYPE" == "pre-commit" ]; then
  gitleaks git --pre-commit --staged --no-banner --redact --verbose
elif [ "$HOOK_TYPE" == "pre-push" ]; then
  BASE_COMMIT=$(git merge-base origin/master HEAD)
  gitleaks git --log-opts="$BASE_COMMIT..HEAD" --no-banner --redact --verbose
else
  cat >&2 <<EOF
ERROR: Unsupported hook type '$HOOK_TYPE'.
Usage: ./$SCRIPT_NAME [pre-commit|pre-push]
EOF
  exit 1
fi

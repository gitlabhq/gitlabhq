#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../config"

CI_CONFIG="$CONFIG_DIR/gitleaks.toml"
LOCAL_CONFIG="$CONFIG_DIR/gitleaks-local.toml"

DRY_RUN=false
if [ "${1:-}" == "--dry-run" ]; then
  DRY_RUN=true
fi

generate_config() {
  cat << 'HEADER'
# AUTO-GENERATED - DO NOT EDIT
# Usage: This is used for running `gitleaks` locally via `lefthook`.
# Source: config/gitleaks.toml
# Regenerate: scripts/generate-gitleaks-local-config.sh

title = "Local gitleaks config - extends gitleaks default ruleset"

[extend]
useDefault = true

# Disabled rules (false positives in doc/api/openapi/openapi_v3.yaml)
disabledRules = ["sourcegraph-access-token"]

HEADER

  sed -n '/^\[allowlist\]/,$p' "$CI_CONFIG"
}

if [ "$DRY_RUN" == "true" ]; then
  generate_config
else
  generate_config > "$LOCAL_CONFIG"
  echo "Generated: $LOCAL_CONFIG"
fi

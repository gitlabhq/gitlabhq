#!/usr/bin/env bash

# Runs any command from local source within `gitlab/` in the context
# of the cluster's toolbox pod via mirrord.
#
# Usage:
#   .gitlab/caproni/exec.sh rake gitlab:graphql:schema:dump
#   .gitlab/caproni/exec.sh rails runner 'puts User.count'
#   .gitlab/caproni/exec.sh $SHELL
#   MIRRORD_CONFIG=rspec .gitlab/caproni/exec.sh ruby bin/rspec spec/…
#
# The mirrord config file is resolved from `.gitlab/caproni/.mirrord/`
# with `$MIRRORD_CONFIG.json`; set MIRRORD_CONFIG to pick a non-default
# config (default: `exec`).
#
# Prerequisites:
# - `scripts/prepare-dev-env.sh` was performed
# - `.gitlab/caproni/setup.sh` was performed

set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <executable> <...>" >&2
  echo "Example: $0 bundle exec rake gitlab:graphql:schema:dump" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONOLITH_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [[ ! -f "$SCRIPT_DIR/.setup-complete" ]]; then
  echo >&2 "ERROR: setup has not run yet. Run 'caproni run' to set up the local environment first."
  exit 1
fi

CONFIG_NAME="${MIRRORD_CONFIG:-exec}"
CONFIG="$MONOLITH_DIR/.gitlab/caproni/.mirrord/${CONFIG_NAME}.json"
TARGET_DEPLOYMENT="deploy/gitlab-toolbox"
TARGET="$TARGET_DEPLOYMENT/container/toolbox"
NAMESPACE="gitlab"
QUOTED_ARGS=$(printf '%q ' "$@")

# Skip dynamic Postgres partition creation during Rails boot. The sync issues
# ~1300 queries / ~9s, meaning skipping it cuts boot time of `rake environment`
# by a third. Partitions are otherwise created by migrations and the
# PartitionManagementWorker cron job in the cluster.
#
# Partition syncing can be enabled by setting DISABLE_POSTGRES_PARTITION_CREATION_ON_STARTUP to 0.
SKIP_PARTITION_CREATION="${DISABLE_POSTGRES_PARTITION_CREATION_ON_STARTUP:-1}"

# PGGSSENCMODE=disable: libpq defaults to gssencmode=prefer, which negotiates
# GSSAPI encryption on connect and loads the macOS Kerberos/GSS framework. That
# code path is not fork-safe, so any forked child (for example parallel RSpec
# workers) can SIGSEGV in pg's native connect_start on its first DB connection.
# Disabling GSS avoids the crash for every command run through this wrapper, and
# replaces the per-connection gssencmode patch that setup.sh used to inject into
# config/database.yml.
COMMAND="export PGGSSENCMODE=disable DISABLE_POSTGRES_PARTITION_CREATION_ON_STARTUP=$SKIP_PARTITION_CREATION && cd $MONOLITH_DIR && mise exec -- $QUOTED_ARGS"

if [[ $OSTYPE == 'darwin'* ]]; then
  if command -v brew >/dev/null 2>&1; then
    libpq_prefix="$(brew --prefix --installed libpq@17 2>/dev/null || brew --prefix --installed libpq 2>/dev/null || true)"
    if [[ -n "$libpq_prefix" && -d "$libpq_prefix/bin" ]]; then
      export PATH="$libpq_prefix/bin:$PATH"
    fi
  fi
fi

kubectl wait --for=condition=Ready pod \
  -l app=toolbox \
  --namespace "$NAMESPACE" \
  --timeout=120s

mirrord exec \
  --config-file "$CONFIG" \
  --target "$TARGET" \
  --target-namespace "$NAMESPACE" \
  -- bash -c "$COMMAND"

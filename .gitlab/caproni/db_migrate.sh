#!/usr/bin/env bash

# Runs `rake db:migrate` from local source within `gitlab/` in the context of
# cluster's database.
#
# Prerequisites:
# - Cluster is up with healthy webservice container in gitlab-webservice-default pod
# - `caproni run` is NOT running
# - `.gitlab/caproni/setup.sh` was performed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONOLITH_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$MONOLITH_DIR/.." && pwd)"

CONFIG="$MONOLITH_DIR/.gitlab/caproni/.mirrord/db_migrate.json"
TARGET_DEPLOYMENT="deploy/gitlab-toolbox"
TARGET="$TARGET_DEPLOYMENT/container/toolbox"
NAMESPACE="gitlab"
COMMAND="cd $MONOLITH_DIR && mise exec -- bundle exec rake db:migrate"

echo "REPO_DIR: ${REPO_DIR}"
echo "MONOLITH_DIR: ${MONOLITH_DIR}"
echo "CONFIG: ${CONFIG}"

if [[ $OSTYPE == 'darwin'* ]]; then
  # libpq bins aren't added to the PATH by default, so we
  # ensure that pg_dump is available for migrations.
  if command -v brew >/dev/null 2>&1; then
    libpq_prefix="$(brew --prefix libpq@16 2>/dev/null || brew --prefix libpq 2>/dev/null || true)"
    if [[ -n "$libpq_prefix" && -d "$libpq_prefix/bin" ]]; then
      export PATH="$libpq_prefix/bin:$PATH"
    fi
  fi
fi

mirrord exec \
  --config-file "$CONFIG" \
  --target "$TARGET" \
  --target-namespace "$NAMESPACE" \
  -- bash -c "$COMMAND"

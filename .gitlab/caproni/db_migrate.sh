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

CONFIG="$MONOLITH_DIR/.gitlab/caproni/.mirrord/db_migrate.json"
MIGRATE_COMMAND="bundle exec rake db:migrate"

# Parse connection parameters from config/database.yml using Ruby stdlib
# (no Rails/Bundler boot required).
# Outputs tab-separated lines: name, host, port, database, username, password
# Only includes databases where database_tasks is not explicitly false.
parse_db_config() {
  local db_config="$MONOLITH_DIR/config/database.yml"

  ruby -ryaml -e '
    config = YAML.safe_load(File.read(ARGV[0]))
    env = ENV["RAILS_ENV"] || "development"
    databases = config[env] || {}
    databases.each do |name, params|
      next unless params.is_a?(Hash)
      next if params["database_tasks"] == false
      puts [
        name,
        params["host"] || "localhost",
        params["port"] || 5432,
        params["database"],
        params["username"] || "",
        params["password"] || ""
      ].join("\t")
    end
  ' "$db_config"
}

# Check for pending migrations by comparing local schema_migrations files
# against the versions applied in the cluster's database.
# This mirrors the logic in GDK's PendingMigrations diagnostic but is
# fully self-contained — no GDK dependency.
check_pending_migrations() {
  local schema_migrations_dir="$MONOLITH_DIR/db/schema_migrations"

  if [[ ! -d "$schema_migrations_dir" ]]; then
    echo "Warning: $schema_migrations_dir not found. Skipping migration."
    return 0
  fi

  # Collect local migration versions (filenames in db/schema_migrations/)
  local local_versions
  local_versions=$(ls "$schema_migrations_dir" | sort)

  if [[ -z "$local_versions" ]]; then
    echo "No local schema migration versions found. Skipping check."
    return 0
  fi

  # Parse database.yml for connection details (Ruby stdlib only, no Rails boot)
  local db_entries
  db_entries=$(parse_db_config)

  if [[ -z "$db_entries" ]]; then
    echo "Warning: No databases with database_tasks: true found in config/database.yml."
    return 0
  fi

  # Query applied versions from each database via psql through mirrord.
  echo "Querying applied migration versions from cluster database..."
  local applied_versions="" query_err
  query_err=$(mktemp)

  while IFS=$'\t' read -r name host port database username password; do
    echo "  Checking database: $name ($database)"
    local versions
    versions=$(PGPASSWORD="$password" "$SCRIPT_DIR/exec.sh" \
      psql -h "$host" -p "$port" -U "$username" -d "$database" \
      -t -A -c "SELECT version FROM schema_migrations" 2>"$query_err") || {
      echo "Warning: Failed to query migration versions from $name ($database). Proceeding with migration."
      echo "Error: $(cat "$query_err")"
      rm -f "$query_err"
      return 1
    }

    if [[ -n "$versions" ]]; then
      applied_versions+="${versions}"$'\n'
    fi
  done <<< "$db_entries"

  # Deduplicate across databases and sort
  applied_versions=$(echo "$applied_versions" | sort -u | sed '/^$/d')
  echo "Applied migration versions count: $(echo "$applied_versions" | wc -l)"
  rm -f "$query_err"

  # Find versions present locally but not applied in the DB
  local pending
  pending=$(comm -23 <(echo "$local_versions") <(echo "$applied_versions"))

  if [[ -n "$pending" ]]; then
    local count
    count=$(echo "$pending" | wc -l | tr -d ' ')
    echo "Pending migration(s) count: $count"
    return 1
  else
    echo "No pending migrations. Database is up to date."
    return 0
  fi
}

if check_pending_migrations; then
  echo "Skipping db:migrate — nothing to do."
else
  echo "Running migration using db:migrate rake command."
  "$SCRIPT_DIR/exec.sh" $MIGRATE_COMMAND
  exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    echo "Error: db:migrate failed with exit code $exit_code"
    exit $exit_code
  fi
fi

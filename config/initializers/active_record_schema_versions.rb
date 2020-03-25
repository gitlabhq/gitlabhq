# frozen_string_literal: true

# Patch to use COPY in db/structure.sql when populating schema_migrations table
# This is intended to reduce potential for merge conflicts in db/structure.sql
ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(Gitlab::Database::PostgresqlAdapter::SchemaVersionsCopyMixin)

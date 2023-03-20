# frozen_string_literal: true

require_relative '../migration_schema_validator'

class SchemaValidator < MigrationSchemaValidator
  ALLOW_SCHEMA_CHANGES = 'ALLOW_SCHEMA_CHANGES'
  COMMIT_MESSAGE_SKIP_TAG = 'skip-db-structure-check'

  def validate!
    return if should_skip?

    return if schema_changes.empty?

    die "#{FILENAME} was changed, and no migrations were added:\n#{schema_changes}" if committed_migrations.empty?
  end

  private

  def schema_changes
    @schema_changes ||= run("git diff #{diff_target} HEAD -- #{FILENAME}")
  end

  def should_skip?
    skip_env_present? || skip_commit_present?
  end

  def skip_env_present?
    !ENV[ALLOW_SCHEMA_CHANGES].to_s.empty?
  end

  def skip_commit_present?
    run("git show -s --format=%B -n 1").to_s.include?(COMMIT_MESSAGE_SKIP_TAG)
  end
end

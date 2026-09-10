# frozen_string_literal: true

require 'spec_helper'

# Enforces the Data Retention Policy Framework against the definitions
# committed to the repository.
# https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/data_retention_policy_framework/
#
# Declarations live in db/docs/data_retention/<table_name>.yml.
#
# The identification method mirrors spec/db/docs_spec.rb: live tables come from
# Gitlab::Database::RetentionPolicy.eligible_tables, deleted tables come from
# Dir.glob over db/docs/deleted_tables/*.yml, so the checks stay in lockstep
# with how the database dictionary itself is validated.

RSpec.describe 'Retention policy definitions', feature_category: :database do
  def retention_policy_file_path(table_name)
    Rails.root.join('db', 'docs', 'data_retention', "#{table_name}.yml")
  end

  def retention_policy_exists?(table_name)
    File.exist?(retention_policy_file_path(table_name))
  end

  describe 'schema coverage' do
    it 'classifies every gitlab_schema as either eligible or excluded' do
      known_schemas = Gitlab::Database::RetentionPolicy::ELIGIBLE_SCHEMAS +
        Gitlab::Database::RetentionPolicy::EXCLUDED_SCHEMAS
      all_schemas = Gitlab::Database::Dictionary.entries.map(&:gitlab_schema).uniq
      unknown = all_schemas - known_schemas

      expect(unknown).to be_empty, <<~MSG
        The following gitlab_schema values are not classified by the Data Retention Policy Framework:

        #{unknown.map { |s| "  - #{s}" }.join("\n")}

        Add each schema to either
        Gitlab::Database::RetentionPolicy::ELIGIBLE_SCHEMAS (tables must declare a retention policy)
        or
        Gitlab::Database::RetentionPolicy::EXCLUDED_SCHEMAS (skipped by the framework).
      MSG
    end

    # gitlab_geo only has tables when the EE Geo connection is loaded, and other
    # EE-only schemas may follow the same pattern. Under as-if-FOSS the ee/ tree
    # is removed, so this reverse check runs in EE only where the full schema
    # universe is visible.
    it 'identifies unknown schemas in declared lists', if: Gitlab.ee? do
      known_schemas = Gitlab::Database::RetentionPolicy::ELIGIBLE_SCHEMAS +
        Gitlab::Database::RetentionPolicy::EXCLUDED_SCHEMAS
      all_schemas = Gitlab::Database::Dictionary.entries.map(&:gitlab_schema).uniq
      unknown = known_schemas - all_schemas

      expect(unknown).to be_empty, <<~MSG
        The following gitlab_schema values classified by the Data Retention Policy Framework but do
        not belong to the available gitlab_schemas:

        #{unknown.map { |s| "  - #{s}" }.join("\n")}

        Remove the schema from either
        Gitlab::Database::RetentionPolicy::ELIGIBLE_SCHEMAS (tables must declare a retention policy)
        or
        Gitlab::Database::RetentionPolicy::EXCLUDED_SCHEMAS (skipped by the framework).
      MSG
    end
  end

  describe 'live tables' do
    let(:tables) { Gitlab::Database::RetentionPolicy.eligible_tables.map(&:table_name) }
    let(:allowlist_relative_path) { 'spec/support/database/retention-policy-missing-allowlist.yml' }
    let(:allowlisted_tables) { YAML.safe_load_file(Rails.root.join(allowlist_relative_path)) }
    let(:missing) { tables.reject { |table_name| retention_policy_exists?(table_name) } }

    it 'requires every table to declare a retention policy, or be explicitly allowlisted' do
      not_allowlisted = missing - allowlisted_tables

      expect(not_allowlisted).to be_empty, <<~MSG
        The following tables do not declare a retention policy in db/docs/data_retention/<table>.yml:

        #{not_allowlisted.map { |t| "  - #{t}" }.join("\n")}

        Every new table must declare a retention policy following the framework:
        https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/data_retention_policy_framework/
      MSG
    end

    it 'does not allow stale entries in the allowlist' do
      # An entry is stale when it is no longer in the set of eligible tables that
      # are missing a retention policy: either the table now declares one, or it
      # was dropped, renamed, or moved to an excluded schema.
      stale = allowlisted_tables - missing

      expect(stale).to be_empty, <<~MSG
        The following tables are listed in #{allowlist_relative_path} but either already declare a
        retention policy or are no longer eligible tables. Remove them from the allowlist:

        #{stale.map { |t| "  - #{t}" }.join("\n")}
      MSG
    end
  end

  describe 'deleted tables' do
    let(:deleted_tables) do
      Dir.glob(Rails.root.join("db/docs/deleted_tables/*.yml"))
         .map { |f| File.basename(f, '.yml') }
         .sort
         .uniq
    end

    it 'does not keep a retention policy for a deleted table' do
      orphaned = deleted_tables.select { |table_name| retention_policy_exists?(table_name) }

      expect(orphaned).to be_empty, <<~MSG
        The following tables were deleted but still have a retention policy declaration.
        Delete these files:

        #{orphaned.map { |t| "  - db/docs/data_retention/#{t}.yml" }.join("\n")}
      MSG
    end
  end

  describe 'declaration files' do
    let(:declaration_files) do
      Dir.glob(Rails.root.join("db/docs/data_retention/*.yml")).uniq
    end

    it 'validates every declaration file committed to the repository' do
      invalid = declaration_files.filter_map do |file_path|
        policy = Gitlab::Database::RetentionPolicy.from_file(file_path)
        errors = policy.validation_errors
        "  #{file_path}\n    #{errors.join("\n    ")}" if errors.any?
      end

      expect(invalid).to be_empty, <<~MSG
        The following retention policy declarations are invalid:

        #{invalid.join("\n")}
      MSG
    end
  end
end

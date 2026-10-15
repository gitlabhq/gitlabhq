# frozen_string_literal: true

# Phase 4, wave 2 of https://gitlab.com/gitlab-org/gitlab/-/work_items/597949: routes deleted
# rows of medium-volume LFK parent tables to the deleted-records table of their sharding key.
# All of them use the standard trigger form today, so `down` restores it as is.
class TrackDeletionsWithShardingKeysWave2 < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  disable_ddl_transaction!
  milestone '19.6'

  TABLES = %i[
    ci_pipeline_artifacts
    duo_workflows_workflows
    issues
    merge_requests
    packages_package_files
    project_wiki_repositories
    vulnerabilities
  ].freeze

  def up
    TABLES.each do |table|
      with_lock_retries { track_record_deletions_with_sharding_keys(table) }
    end
  end

  def down
    TABLES.each do |table|
      with_lock_retries do
        execute(<<~SQL.squish)
          CREATE OR REPLACE TRIGGER #{table}_loose_fk_trigger
          AFTER DELETE ON #{table} REFERENCING OLD TABLE AS old_table
          FOR EACH STATEMENT
          EXECUTE FUNCTION #{INSERT_FUNCTION_NAME}();
        SQL
      end
    end
  end
end

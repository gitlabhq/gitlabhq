# frozen_string_literal: true

class RenameGetPreviousSessionContextToolRules < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  OLD_NAME = 'get_previous_session_context'
  NEW_NAME = 'get_session_context'
  ACCESS_COLUMNS = %i[web_access local_access background_access].freeze

  class MigrationAiToolRule < MigrationRecord
    include EachBatch

    self.table_name = 'ai_tool_rules'
  end

  def up
    MigrationAiToolRule.where(tool_name: OLD_NAME).each_batch(of: 100) do |relation|
      relation.each do |rule|
        fresh_rule = find_fresh_rule(rule)

        if fresh_rule
          merge_stale_into_fresh(rule, fresh_rule)
        else
          begin
            rule.update_column(:tool_name, NEW_NAME)
          rescue ActiveRecord::RecordNotUnique
            # Post-deploy migration: a get_session_context row can be created concurrently,
            # between find_fresh_rule above and this update.
            fresh_rule = find_fresh_rule(rule)
            raise unless fresh_rule

            merge_stale_into_fresh(rule, fresh_rule)
          end
        end
      end
    end
  end

  def down
    # no-op: renamed rows can't be distinguished from rows already named get_session_context
    # before this ran, and merged/deleted rows can't be split back apart
  end

  private

  def find_fresh_rule(stale_rule)
    MigrationAiToolRule.find_by(
      namespace_id: stale_rule.namespace_id,
      project_id: stale_rule.project_id,
      tool_name: NEW_NAME
    )
  end

  # A get_session_context row can already exist if an admin configured it after the tool
  # renamed in code but before this migration ran. Its explicitly-set columns reflect a real,
  # current decision and are kept as-is; any column it left unset gets backfilled from the
  # stale row instead of silently defaulting, since the rename bug hid that surface's history
  # from the admin when they made that edit.
  def merge_stale_into_fresh(stale_rule, fresh_rule)
    backfill = ACCESS_COLUMNS.index_with { |column| fresh_rule[column] || stale_rule[column] }

    fresh_rule.update_columns(backfill)
    stale_rule.delete

    Gitlab::AppLogger.warn(
      message: "Merged stale ai_tool_rules row into get_session_context row for the same namespace/project",
      ai_tool_rule_id: stale_rule.id,
      Labkit::Fields::GL_NAMESPACE_ID => stale_rule.namespace_id,
      Labkit::Fields::GL_PROJECT_ID => stale_rule.project_id
    )
  end
end

# frozen_string_literal: true

class BackfillInternalIdsWithIssuesUsageForEpics < Gitlab::Database::Migration[2.2]
  milestone '16.8'
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  BATCH_SIZE = 500
  ISSUES_USAGE = 0 # see Enums::InternalId#usage_resources[:issues]
  EPICS_USAGE = 4 # see Enums::InternalId#usage_resources[:epics]

  def up
    internal_id_model = define_batchable_model('internal_ids')
    epic_model = define_batchable_model('epics')

    internal_id_model.where(usage: EPICS_USAGE).each_batch(of: BATCH_SIZE) do |relation|
      # Creates a corresponding `usage: :issues` record for every `epics` usage.
      # On conflict it means the record was already created when a new epic was created with the newly issues usage.
      # In which case to make sure we have the value copied over from epics record.
      connection.execute(
        <<~SQL
          INSERT INTO internal_ids (usage, last_value, namespace_id)
            SELECT #{ISSUES_USAGE}, last_value, namespace_id
            FROM internal_ids
            WHERE internal_ids.id IN(#{relation.select(:id).to_sql})
          ON CONFLICT (usage, namespace_id) WHERE namespace_id IS NOT NULL
          DO UPDATE SET last_value = GREATEST(EXCLUDED.last_value, internal_ids.last_value)
          RETURNING id;
        SQL
      )

      relation.delete_all
    end

    # there are a couple records in epics table that reference namespaces without a corresponding entry
    # in internal_ids, for whatever reason, so this statement addresses that.
    epic_model.distinct_each_batch(column: :group_id, of: BATCH_SIZE) do |relation|
      connection.execute(
        <<~SQL
          INSERT INTO internal_ids (usage, last_value, namespace_id)
            SELECT #{ISSUES_USAGE}, max(iid) as last_value, group_id
            FROM epics
            WHERE group_id IN(#{relation.to_sql})
            GROUP BY group_id
          ON CONFLICT (usage, namespace_id) WHERE namespace_id IS NOT NULL
          DO NOTHING
          RETURNING id;
        SQL
      )
    end
  end

  def down
    # noop
  end
end

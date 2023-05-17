# frozen_string_literal: true

class RemoveUserNamespaceRecordsFromVsaAggregation < Gitlab::Database::Migration[2.1]
  BATCH_SIZE = 100

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    aggregations_model = define_batchable_model('analytics_cycle_analytics_aggregations')
    namespaces_model = define_batchable_model('namespaces')

    aggregations_model.each_batch(of: BATCH_SIZE) do |relation|
      inner_query = namespaces_model
        .where(type: 'Group')
        .where(aggregations_model.arel_table[:group_id].eq(namespaces_model.arel_table[:id]))

      relation.where('NOT EXISTS (?)', inner_query).delete_all
    end
  end

  def down
    # noop
  end
end

# frozen_string_literal: true

# Sync remaining records for issues/merge_requests tables where state_id
# is still null.
# For more information check: https://gitlab.com/gitlab-org/gitlab/issues/26823
# It creates a temporary index before performing the UPDATES to sync values.
#
# In 09-11-2019 we have the following numbers for records with state_id == nil:
#
# 1348 issues - default batch size for each update 67
# 10247 merge requests - default batch size for each update 511

class SyncIssuablesStateId < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    %i(issues merge_requests).each do |table|
      temp_index_name = index_name_for(table)

      add_concurrent_index(
        table,
        'id',
        name: temp_index_name,
        where: 'state_id IS NULL'
      )

      update_value = update_condition_for(table)

      update_column_in_batches(table, :state_id, update_value) do |table, query|
        query.where(table[:state_id].eq(nil))
      end
    ensure
      remove_concurrent_index_by_name(table, temp_index_name)
    end
  end

  def down
    # NO OP
  end

  def update_condition_for(table)
    value_expresson =
      if table == :issues
        issues_state_id_condition
      else
        merge_requests_state_id_condition
      end

    Arel.sql(value_expresson)
  end

  def index_name_for(table)
    "idx_tmp_on_#{table}_where_state_id_is_null"
  end

  def issues_state_id_condition
    <<~SQL
      CASE state
      WHEN 'opened' THEN 1
      WHEN 'closed' THEN 2
      ELSE 2
      END
    SQL
  end

  def merge_requests_state_id_condition
    <<~SQL
      CASE state
      WHEN 'opened' THEN 1
      WHEN 'closed' THEN 2
      WHEN 'merged' THEN 3
      WHEN 'locked' THEN 4
      ELSE 2
      END
    SQL
  end
end

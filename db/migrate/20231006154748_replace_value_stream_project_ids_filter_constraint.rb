# frozen_string_literal: true

class ReplaceValueStreamProjectIdsFilterConstraint < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  OLD_CONSTRAINT_NAME = 'chk_rails_a91b547c97'
  NEW_CONSTRAINT_NAME = 'project_ids_filter_array_check'

  def up
    remove_check_constraint :analytics_cycle_analytics_value_stream_settings, OLD_CONSTRAINT_NAME

    check = '((CARDINALITY(project_ids_filter) <= 100) AND (ARRAY_POSITION(project_ids_filter, null) IS null))'
    add_check_constraint :analytics_cycle_analytics_value_stream_settings, check, NEW_CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :analytics_cycle_analytics_value_stream_settings, NEW_CONSTRAINT_NAME

    check = '(CARDINALITY(project_ids_filter) <= 100)'
    add_check_constraint :analytics_cycle_analytics_value_stream_settings, check, OLD_CONSTRAINT_NAME
  end
end

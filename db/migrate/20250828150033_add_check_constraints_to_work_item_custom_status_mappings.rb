# frozen_string_literal: true

class AddCheckConstraintsToWorkItemCustomStatusMappings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  def up
    # DB level constraint for the no_self_mapping model validation
    add_check_constraint :work_item_custom_status_mappings,
      'old_status_id != new_status_id',
      old_new_status_constraint_name

    # DB level constraint for the valid_date_range model validation
    add_check_constraint :work_item_custom_status_mappings,
      'valid_from IS NULL OR valid_until IS NULL OR valid_from < valid_until',
      date_range_constraint_name
  end

  def down
    remove_check_constraint :work_item_custom_status_mappings, old_new_status_constraint_name
    remove_check_constraint :work_item_custom_status_mappings, date_range_constraint_name
  end

  private

  def old_new_status_constraint_name
    check_constraint_name(:work_item_custom_status_mappings, :old_status_id, 'not_equal_new_status_id')
  end

  def date_range_constraint_name
    check_constraint_name(:work_item_custom_status_mappings, :valid_from, 'before_valid_until')
  end
end

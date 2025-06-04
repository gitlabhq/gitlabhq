# frozen_string_literal: true

class AddConvertedFromSystemDefinedStatusIdToCustomStatuses < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def change
    add_column :work_item_custom_statuses, :converted_from_system_defined_status_identifier, :smallint
  end
end

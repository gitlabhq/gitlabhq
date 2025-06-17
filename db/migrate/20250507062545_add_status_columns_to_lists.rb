# frozen_string_literal: true

class AddStatusColumnsToLists < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def change
    add_column :lists, :custom_status_id, :bigint
    add_column :lists, :system_defined_status_identifier, :smallint
  end
end

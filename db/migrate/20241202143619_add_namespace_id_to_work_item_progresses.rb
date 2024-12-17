# frozen_string_literal: true

class AddNamespaceIdToWorkItemProgresses < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :work_item_progresses, :namespace_id, :bigint
  end
end

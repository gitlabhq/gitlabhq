# frozen_string_literal: true

class AddGroupIdToDependencyListExports < Gitlab::Database::Migration[2.1]
  def change
    add_column :dependency_list_exports, :group_id, :bigint
  end
end

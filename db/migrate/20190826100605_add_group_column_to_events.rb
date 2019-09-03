# frozen_string_literal: true

class AddGroupColumnToEvents < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_reference :events, :group, index: true, foreign_key: { to_table: :namespaces, on_delete: :cascade }
  end
end

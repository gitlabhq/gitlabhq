# frozen_string_literal: true

class AddArchivedToLabel < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def change
    add_column :labels, :archived, :boolean, default: false, null: false
  end
end

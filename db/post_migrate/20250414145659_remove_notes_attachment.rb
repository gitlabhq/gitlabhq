# frozen_string_literal: true

class RemoveNotesAttachment < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  def change
    remove_column :notes, :attachment, :string
  end
end

# frozen_string_literal: true

class AddMarkForDeletionToNamespaces < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :namespaces, :marked_for_deletion_at, :date
    add_column :namespaces, :marked_for_deletion_by_user_id, :integer
  end
end

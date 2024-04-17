# frozen_string_literal: true

class AddImportedToMergeRequests < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def change
    add_column :merge_requests, :imported, :integer, default: 0, null: false, limit: 2
  end
end

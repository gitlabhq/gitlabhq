# frozen_string_literal: true

class AddRetargetedToMergeRequests < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  def change
    add_column :merge_requests, :retargeted, :boolean, default: false, null: false
  end
end

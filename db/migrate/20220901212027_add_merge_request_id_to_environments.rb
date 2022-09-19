# frozen_string_literal: true

class AddMergeRequestIdToEnvironments < Gitlab::Database::Migration[2.0]
  def change
    add_column :environments, :merge_request_id, :bigint
  end
end

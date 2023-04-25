# frozen_string_literal: true

class AddStatusToStatusCheckResponses < Gitlab::Database::Migration[1.0]
  def change
    add_column :status_check_responses, :status, :integer, default: 0, null: false, limit: 2
  end
end

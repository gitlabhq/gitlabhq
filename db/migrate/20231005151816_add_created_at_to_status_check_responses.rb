# frozen_string_literal: true

class AddCreatedAtToStatusCheckResponses < Gitlab::Database::Migration[2.1]
  def change
    add_column :status_check_responses, :created_at, :datetime_with_timezone, null: false, default: -> { 'NOW()' }
  end
end

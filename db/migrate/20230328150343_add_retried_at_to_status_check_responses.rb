# frozen_string_literal: true

class AddRetriedAtToStatusCheckResponses < Gitlab::Database::Migration[2.1]
  def change
    add_column :status_check_responses, :retried_at, :datetime_with_timezone
  end
end

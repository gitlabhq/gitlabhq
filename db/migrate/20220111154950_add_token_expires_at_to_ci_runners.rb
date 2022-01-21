# frozen_string_literal: true

class AddTokenExpiresAtToCiRunners < Gitlab::Database::Migration[1.0]
  def change
    add_column :ci_runners, :token_expires_at, :datetime_with_timezone
  end
end

# frozen_string_literal: true

class AddLastVerifiedAtToSecretDetectionTokenStatus < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def change
    add_column :secret_detection_token_statuses,
      :last_verified_at,
      :datetime_with_timezone
  end
end

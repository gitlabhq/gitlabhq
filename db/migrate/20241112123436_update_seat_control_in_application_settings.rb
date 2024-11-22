# frozen_string_literal: true

class UpdateSeatControlInApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  enable_lock_retries!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    execute <<~SQL
      UPDATE application_settings
      SET user_seat_management = jsonb_build_object(
        'seat_control', CASE WHEN new_user_signups_cap IS NULL THEN 0 ELSE 1 END
      );
    SQL
  end

  def down
    # no-op
  end
end

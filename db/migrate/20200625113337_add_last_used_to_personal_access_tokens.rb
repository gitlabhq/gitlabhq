# frozen_string_literal: true

class AddLastUsedToPersonalAccessTokens < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      add_column :personal_access_tokens, :last_used_at, :datetime_with_timezone
    end
  end

  def down
    with_lock_retries do
      remove_column :personal_access_tokens, :last_used_at, :datetime_with_timezone
    end
  end
end

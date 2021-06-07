# frozen_string_literal: true

class AddPronounsToUserDetails < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    # rubocop:disable Migration/AddLimitToTextColumns
    # limit is added in 20210607050531_add_text_limit_to_user_details_pronouns
    with_lock_retries do
      add_column :user_details, :pronouns, :text, null: true
    end
    # rubocop:enable Migration/AddLimitToTextColumns
  end

  def down
    with_lock_retries do
      remove_column :user_details, :pronouns
    end
  end
end

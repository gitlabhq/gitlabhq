# frozen_string_literal: true

class AddPronunciationToUserDetails < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    # rubocop:disable Migration/AddLimitToTextColumns
    # limit is added in 20210729061556_add_text_limit_to_user_details_pronunciation.rb
    with_lock_retries do
      add_column :user_details, :pronunciation, :text, null: true
    end
    # rubocop:enable Migration/AddLimitToTextColumns
  end

  def down
    with_lock_retries do
      remove_column :user_details, :pronunciation
    end
  end
end

# frozen_string_literal: true

class AddTextLimitToUserDetailsPronouns < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_text_limit :user_details, :pronouns, 50
  end

  def down
    remove_text_limit :user_details, :pronouns
  end
end

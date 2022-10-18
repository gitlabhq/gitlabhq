# frozen_string_literal: true

class AddUserDetailsFieldLimits < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  USER_DETAILS_FIELD_LIMIT = 500

  def up
    add_text_limit :user_details, :linkedin, USER_DETAILS_FIELD_LIMIT
    add_text_limit :user_details, :twitter, USER_DETAILS_FIELD_LIMIT
    add_text_limit :user_details, :skype, USER_DETAILS_FIELD_LIMIT
    add_text_limit :user_details, :website_url, USER_DETAILS_FIELD_LIMIT
    add_text_limit :user_details, :location, USER_DETAILS_FIELD_LIMIT
    add_text_limit :user_details, :organization, USER_DETAILS_FIELD_LIMIT
  end

  def down
    remove_text_limit :user_details, :linkedin
    remove_text_limit :user_details, :twitter
    remove_text_limit :user_details, :skype
    remove_text_limit :user_details, :website_url
    remove_text_limit :user_details, :location
    remove_text_limit :user_details, :organization
  end
end

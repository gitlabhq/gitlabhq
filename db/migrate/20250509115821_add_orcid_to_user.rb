# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddOrcidToUser < Gitlab::Database::Migration[2.3]
  USER_DETAILS_FIELD_LIMIT = 256
  disable_ddl_transaction!

  milestone '18.0'

  def up
    with_lock_retries do
      add_column :user_details, :orcid, :text, default: '', null: false, if_not_exists: true
    end

    add_text_limit :user_details, :orcid, USER_DETAILS_FIELD_LIMIT
  end

  def down
    with_lock_retries do
      remove_column :user_details, :orcid
    end
  end
end

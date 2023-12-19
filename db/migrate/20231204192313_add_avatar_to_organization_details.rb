# frozen_string_literal: true

class AddAvatarToOrganizationDetails < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.7'

  def up
    with_lock_retries do
      add_column :organization_details, :avatar, :text, if_not_exists: true
    end

    add_text_limit :organization_details, :avatar, 255
  end

  def down
    with_lock_retries do
      remove_column :organization_details, :avatar, if_exists: true
    end
  end
end

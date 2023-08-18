# frozen_string_literal: true

class AddNameAndDescriptionToMemberRoles < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :member_roles, :name, :text, null: false, default: 'Custom', if_not_exists: true
      add_column :member_roles, :description, :text, if_not_exists: true
    end

    add_text_limit :member_roles, :name, 255
    add_text_limit :member_roles, :description, 255
  end

  def down
    with_lock_retries do
      remove_column :member_roles, :name, :text, if_exists: true
      remove_column :member_roles, :description, :text, if_exists: true
    end
  end
end

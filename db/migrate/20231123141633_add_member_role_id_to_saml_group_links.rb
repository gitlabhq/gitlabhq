# frozen_string_literal: true

class AddMemberRoleIdToSamlGroupLinks < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  enable_lock_retries!

  def change
    add_column :saml_group_links, :member_role_id, :bigint
  end
end

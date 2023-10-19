# frozen_string_literal: true

class AddManageProjectAccessTokensToMemberRoles < Gitlab::Database::Migration[2.1]
  def change
    add_column :member_roles, :manage_project_access_tokens, :boolean, default: false, null: false
  end
end

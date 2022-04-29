# frozen_string_literal: true

class AddGroupInheritanceTypeToPeAuthorizable < Gitlab::Database::Migration[2.0]
  def change
    add_column :protected_environment_deploy_access_levels,
               :group_inheritance_type,
               :smallint,
               default: 0, limit: 2, null: false
    add_column :protected_environment_approval_rules,
               :group_inheritance_type,
               :smallint,
               default: 0, limit: 2, null: false
  end
end

# frozen_string_literal: true

class AddCanPushToGroupDeployKeysGroups < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :group_deploy_keys_groups, :can_push, :boolean, default: false, null: false
  end
end

# frozen_string_literal: true
class AddProtectedEnvironmentDeployAccessLevelTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  GITLAB_ACCESS_MAINTAINER = 40

  def up
    create_table :protected_environment_deploy_access_levels do |t|
      t.timestamps_with_timezone null: false
      t.integer :access_level, default: GITLAB_ACCESS_MAINTAINER, null: true
      t.references :protected_environment, index: { name: 'index_protected_environment_deploy_access' }, foreign_key: { on_delete: :cascade }, null: false
      t.references :user, index: true, foreign_key: { on_delete: :cascade }
      t.references :group, references: :namespace, column: :group_id, index: true
      t.foreign_key :namespaces, column: :group_id, on_delete: :cascade
    end
  end

  def down
    if foreign_keys_for(:protected_environment_deploy_access_levels, :group_id).any?
      remove_foreign_key :protected_environment_deploy_access_levels, column: :group_id
    end

    if foreign_keys_for(:protected_environment_deploy_access_levels, :user_id).any?
      remove_foreign_key :protected_environment_deploy_access_levels, column: :user_id
    end

    drop_table :protected_environment_deploy_access_levels
  end
end

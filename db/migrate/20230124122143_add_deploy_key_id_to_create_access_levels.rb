# frozen_string_literal: true

class AddDeployKeyIdToCreateAccessLevels < Gitlab::Database::Migration[2.1]
  def up
    add_column :protected_tag_create_access_levels, :deploy_key_id, :integer
  end

  def down
    remove_column :protected_tag_create_access_levels, :deploy_key_id
  end
end

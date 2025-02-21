# frozen_string_literal: true

class AddGroupIdToPackagesDebianGroupComponentFiles < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    add_column :packages_debian_group_component_files, :group_id, :bigint
  end
end

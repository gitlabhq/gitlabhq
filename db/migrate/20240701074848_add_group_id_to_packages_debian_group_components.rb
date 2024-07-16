# frozen_string_literal: true

class AddGroupIdToPackagesDebianGroupComponents < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def change
    add_column :packages_debian_group_components, :group_id, :bigint
  end
end

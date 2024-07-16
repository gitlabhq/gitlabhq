# frozen_string_literal: true

class AddGroupIdToPackagesDebianGroupArchitectures < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def change
    add_column :packages_debian_group_architectures, :group_id, :bigint
  end
end

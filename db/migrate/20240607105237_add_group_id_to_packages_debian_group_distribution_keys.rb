# frozen_string_literal: true

class AddGroupIdToPackagesDebianGroupDistributionKeys < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :packages_debian_group_distribution_keys, :group_id, :bigint
  end
end

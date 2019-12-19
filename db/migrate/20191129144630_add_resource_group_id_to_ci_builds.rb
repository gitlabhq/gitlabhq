# frozen_string_literal: true

class AddResourceGroupIdToCiBuilds < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    unless column_exists?(:ci_builds, :resource_group_id)
      add_column :ci_builds, :resource_group_id, :bigint
    end

    unless column_exists?(:ci_builds, :waiting_for_resource_at)
      add_column :ci_builds, :waiting_for_resource_at, :datetime_with_timezone
    end
  end

  def down
    if column_exists?(:ci_builds, :resource_group_id)
      remove_column :ci_builds, :resource_group_id, :bigint
    end

    if column_exists?(:ci_builds, :waiting_for_resource_at)
      remove_column :ci_builds, :waiting_for_resource_at, :datetime_with_timezone
    end
  end
end

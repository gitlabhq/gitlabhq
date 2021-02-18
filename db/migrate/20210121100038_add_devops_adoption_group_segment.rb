# frozen_string_literal: true

class AddDevopsAdoptionGroupSegment < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column :analytics_devops_adoption_segments, :namespace_id, :integer, if_not_exists: true
    add_concurrent_index :analytics_devops_adoption_segments, :namespace_id, unique: true
  end

  def down
    remove_column :analytics_devops_adoption_segments, :namespace_id
  end
end

# frozen_string_literal: true

class OptionalDevopsAdoptionSegmentName < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'index_analytics_devops_adoption_segments_on_name'

  def up
    change_column_null :analytics_devops_adoption_segments, :name, true
    remove_concurrent_index_by_name :analytics_devops_adoption_segments, INDEX_NAME
  end

  def down
    transaction do
      execute "DELETE FROM analytics_devops_adoption_segments WHERE name IS NULL"
      change_column_null :analytics_devops_adoption_segments, :name, false
    end
    add_concurrent_index :analytics_devops_adoption_segments, :name, unique: true, name: INDEX_NAME
  end
end

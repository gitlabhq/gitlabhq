# frozen_string_literal: true

class RemoveObsoleteSegmentsField < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_column :analytics_devops_adoption_segments, :name
    end
  end

  def down
    add_column :analytics_devops_adoption_segments, :name, :text
    add_text_limit :analytics_devops_adoption_segments, :name, 255
  end
end

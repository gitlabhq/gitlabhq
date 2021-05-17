# frozen_string_literal: true

class AddSnapshotNamespaceId < ActiveRecord::Migration[6.0]
  def change
    add_column :analytics_devops_adoption_snapshots, :namespace_id, :integer
  end
end

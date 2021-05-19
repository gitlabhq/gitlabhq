# frozen_string_literal: true

class AddDisplayNamespaceIdToSegments < ActiveRecord::Migration[6.0]
  def change
    add_column :analytics_devops_adoption_segments, :display_namespace_id, :integer
  end
end

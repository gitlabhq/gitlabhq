# frozen_string_literal: true

class RemoveReferenceColumnsFromResourceMilestoneEvents < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    remove_column :resource_milestone_events, :reference, :text
    remove_column :resource_milestone_events, :reference_html, :text
    remove_column :resource_milestone_events, :cached_markdown_version, :integer
  end
end

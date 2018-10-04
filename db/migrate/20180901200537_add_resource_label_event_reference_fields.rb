# frozen_string_literal: true

class AddResourceLabelEventReferenceFields < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :resource_label_events, :cached_markdown_version, :integer
    add_column :resource_label_events, :reference, :text
    add_column :resource_label_events, :reference_html, :text
  end
end

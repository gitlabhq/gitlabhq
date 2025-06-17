# frozen_string_literal: true

class DropResourceLabelEventsReferenceHtml < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def change
    remove_column :resource_label_events, :reference_html, :text
    remove_column :resource_label_events, :cached_markdown_version, :integer
  end
end

class AddVersionFieldToMarkdownCache < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    %i[
      abuse_reports
      appearances
      application_settings
      broadcast_messages
      issues
      labels
      merge_requests
      milestones
      namespaces
      notes
      projects
      releases
      snippets
    ].each do |table|
      add_column table, :cached_markdown_version, :integer, limit: 4
    end
  end
end

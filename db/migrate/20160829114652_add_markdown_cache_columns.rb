# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddMarkdownCacheColumns < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  COLUMNS = {
    abuse_reports: [:message],
    appearances: [:description],
    application_settings: [
      :sign_in_text,
      :help_page_text,
      :shared_runners_text,
      :after_sign_up_text
    ],
    broadcast_messages: [:message],
    issues: [:title, :description],
    labels: [:description],
    merge_requests: [:title, :description],
    milestones: [:title, :description],
    namespaces: [:description],
    notes: [:note],
    projects: [:description],
    releases: [:description],
    snippets: [:title, :content],
  }

  def change
    COLUMNS.each do |table, columns|
      columns.each do |column|
        add_column table, "#{column}_html", :text
      end
    end
  end
end

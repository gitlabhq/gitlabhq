# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddHasExternalIssueTrackerToProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  def change
    add_column(:projects, :has_external_issue_tracker, :boolean)
  end
end

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CleanUpPendingDeleteProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    Project.unscoped.where(pending_delete: true).each { |project| delete_project(project, admin) }
  end

  def down
    # noop
  end

  private

  def delete_project(project)
    project.team.truncate

    unlink_fork(project) if project.forked?

    [:events, :issues, :merge_requests, :labels, :milestones, :notes, :snippets].each do |thing|
      project.send(thing).delete_all
    end

    # Override Project#remove_pages for this instance so it doesn't do anything
    def project.remove_pages
    end

    project.destroy!
  end

  def unlink_fork(project)
    merge_requests = project.forked_from_project.merge_requests.opened.from_project(project)

    merge_requests.update_all(state: 'closed')

    project.forked_project_link.destroy
  end
end

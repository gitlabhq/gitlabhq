# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RenameWildcardProjectNames < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  include Gitlab::ShellAdapter
  disable_ddl_transaction!

  DOWNTIME = false
  KNOWN_PATHS = %w[info git-upload-pack
                   git-receive-pack gitlab-lfs autocomplete_sources
                   templates avatar commit pages compare network snippets
                   services mattermost deploy_keys forks import merge_requests
                   branches merged_branches tags protected_branches variables
                   triggers pipelines environments cycle_analytics builds
                   hooks container_registry milestones labels issues
                   project_members group_links notes noteable boards todos
                   uploads runners runner_projects settings repository
                   transfer remove_fork archive unarchive housekeeping
                   toggle_star preview_markdown export remove_export
                   generate_new_export download_export activity
                   new_issue_address].freeze

  def up
    reserved_projects.find_in_batches(batch_size: 100) do |slice|
      rename_projects(slice)
    end
  end

  def down
    # nothing to do here
  end

  private

  def reserved_projects
    Project.unscoped.
      includes(:namespace).
      where('EXISTS (SELECT 1 FROM namespaces WHERE projects.namespace_id = namespaces.id)').
      where('projects.path' => KNOWN_PATHS)
  end

  def route_exists?(full_path)
    quoted_path = ActiveRecord::Base.connection.quote_string(full_path.downcase)

    ActiveRecord::Base.connection.
      select_all("SELECT id, path FROM routes WHERE lower(path) = '#{quoted_path}'").present?
  end

  # Adds number to the end of the path that is not taken by other route
  def rename_path(namespace_path, path_was)
    counter = 0
    path = "#{path_was}#{counter}"

    while route_exists?("#{namespace_path}/#{path}")
      counter += 1
      path = "#{path_was}#{counter}"
    end

    path
  end

  def rename_projects(projects)
    projects.each do |project|
      id = project.id
      path_was = project.path
      namespace_path = project.namespace.path
      path = rename_path(namespace_path, path_was)

      begin
        # Because project path update is quite complex operation we can't safely
        # copy-paste all code from GitLab. As exception we use Rails code here
        project.rename_repo if rename_project_row(project, path)
      rescue Exception => e # rubocop: disable Lint/RescueException
        Rails.logger.error "Exception when renaming project #{id}: #{e.message}"
      end
    end
  end

  def rename_project_row(project, path)
    project.respond_to?(:update_attributes) &&
      project.update_attributes(path: path) &&
      project.respond_to?(:rename_repo)
  end
end

class RenameReservedProjectNames < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  include Gitlab::ShellAdapter

  DOWNTIME = false

  class Project < ActiveRecord::Base; end

  def up
    threads = reserved_projects.each_slice(100).map do |slice|
      Thread.new do
        rename_projects(slice)
      end
    end

    threads.each(&:join)
  end

  def down
    # nothing to do here
  end

  private

  def reserved_projects
    select_all("SELECT p.id, p.path, p.repository_storage, n.path AS namespace_path, n.id AS namespace_id FROM projects p
               INNER JOIN namespaces n ON n.id = p.namespace_id
               WHERE p.path IN (
               '.well-known', 'all', 'assets', 'files', 'groups', 'hooks', 'issues',
               'merge_requests', 'new', 'profile', 'projects', 'public', 'repository',
               'robots.txt', 's', 'snippets', 'teams', 'u', 'unsubscribes', 'users',
               'tree', 'commits', 'wikis', 'new', 'edit', 'create', 'update', 'logs_tree',
               'preview', 'blob', 'blame', 'raw', 'files', 'create_dir', 'find_file')")
  end

  def route_exists?(full_path)
    select_all("SELECT id, path FROM routes WHERE path = '#{quote_string(full_path)}'").present?
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
    projects.each do |row|
      id = row['id']
      path_was = row['path']
      namespace_path = row['namespace_path']
      path = rename_path(namespace_path, path_was)
      project = Project.find_by(id: id)

      begin
        # Because project path update is quite complex operation we can't safely
        # copy-paste all code from GitLab. As exception we use Rails code here
        if project &&
          project.respond_to?(:update_attributes) &&
          project.update_attributes(path: path) &&
          project.respond_to?(:rename_repo)

          project.rename_repo
        end
      rescue => e
        Rails.logger.error "Exception when rename project #{id}: #{e.message}"
      end
    end
  end
end

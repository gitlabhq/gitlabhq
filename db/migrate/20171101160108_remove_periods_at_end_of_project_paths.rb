class RemovePeriodsAtEndOfProjectPaths < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  include Gitlab::ShellAdapter

  DOWNTIME = false

  RenameProjectError = Class.new(StandardError)

  def up
    queries = [
      "projects.path LIKE '-%'",
      "projects.path LIKE '%.'",
      "projects.path LIKE '%.git'",
      "projects.path LIKE '%.atom'"
    ]

    queries.each do |relation|
      Project.includes(:route, namespace: [:route]).where(relation)
        .find_in_batches(batch_size: 100) do |batch|
        rename_projects(batch)
      end
    end
  end

  def down
  end

  private

  def route_exists?(full_path)
    quoted_path = ActiveRecord::Base.connection.quote_string(full_path)

    ActiveRecord::Base.connection.select_all("SELECT id, path FROM routes WHERE path = '#{quoted_path}'").present?
  end

  def rename_path(namespace_full_path, path_was)
    path = path_was.dup

    # Remove periods .git and .atom at the end of a project path
    path.gsub!(/(\.|\.git|\.atom)+\z/, "")
    # Remove dashes at the start of the project path.
    path.gsub!(/\A-+/, "")

    counter = 0
    while route_exists?("#{namespace_full_path}/#{path}")
      path = "#{path}#{counter}"
      counter += 1
    end

    path
  end

  def rename_projects(projects)
    projects.each do |project|
      id = project.id
      path_was = project.path
      namespace_full_path = project.namespace.full_path
      path = rename_path(namespace_full_path, path_was)

      begin
        raise RenameProjectError, "Failed to update path." unless rename_project_row(project, path)

        project.rename_repo
      rescue Exception => e # rubocop: disable Lint/RescueException
        Rails.logger.error "Exception when renaming project #{id}: #{e.message}"
        raise
      end
    end
  end

  def rename_project_row(project, path)
    project.path = path
    project.save(validate: false) && project.respond_to?(:rename_repo)
  end
end

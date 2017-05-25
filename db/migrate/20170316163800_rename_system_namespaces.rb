# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.
class RenameSystemNamespaces < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  include Gitlab::ShellAdapter
  disable_ddl_transaction!

  class User < ActiveRecord::Base
    self.table_name = 'users'
  end

  class Namespace < ActiveRecord::Base
    self.table_name = 'namespaces'
    belongs_to :parent, class_name: 'RenameSystemNamespaces::Namespace'
    has_one :route, as: :source
    has_many :children, class_name: 'RenameSystemNamespaces::Namespace', foreign_key: :parent_id
    belongs_to :owner, class_name: 'RenameSystemNamespaces::User'

    # Overridden to have the correct `source_type` for the `route` relation
    def self.name
      'Namespace'
    end

    def full_path
      if route && route.path.present?
        @full_path ||= route.path
      else
        update_route if persisted?

        build_full_path
      end
    end

    def build_full_path
      if parent && path
        parent.full_path + '/' + path
      else
        path
      end
    end

    def update_route
      prepare_route
      route.save
    end

    def prepare_route
      route || build_route(source: self)
      route.path = build_full_path
      route.name = build_full_name
      @full_path = nil
      @full_name = nil
    end

    def build_full_name
      if parent && name
        parent.human_name + ' / ' + name
      else
        name
      end
    end

    def human_name
      owner&.name
    end
  end

  class Route < ActiveRecord::Base
    self.table_name = 'routes'
    belongs_to :source, polymorphic: true
  end

  class Project < ActiveRecord::Base
    self.table_name = 'projects'

    def repository_storage_path
      Gitlab.config.repositories.storages[repository_storage]['path']
    end
  end

  DOWNTIME = false

  def up
    return unless system_namespace

    old_path = system_namespace.path
    old_full_path = system_namespace.full_path
    # Only remove the last occurrence of the path name to get the parent namespace path
    namespace_path = remove_last_occurrence(old_full_path, old_path)
    new_path = rename_path(namespace_path, old_path)
    new_full_path = join_namespace_path(namespace_path, new_path)

    Namespace.where(id: system_namespace).update_all(path: new_path) # skips callbacks & validations

    replace_statement = replace_sql(Route.arel_table[:path], old_full_path, new_full_path)
    route_matches = [old_full_path, "#{old_full_path}/%"]

    update_column_in_batches(:routes, :path, replace_statement) do |table, query|
      query.where(Route.arel_table[:path].matches_any(route_matches))
    end

    clear_cache_for_namespace(system_namespace)

    # tasks here are based on `Namespace#move_dir`
    move_repositories(system_namespace, old_full_path, new_full_path)
    move_namespace_folders(uploads_dir, old_full_path, new_full_path) if file_storage?
    move_namespace_folders(pages_dir, old_full_path, new_full_path)
  end

  def down
    # nothing to do
  end

  def remove_last_occurrence(string, pattern)
    string.reverse.sub(pattern.reverse, "").reverse
  end

  def move_namespace_folders(directory, old_relative_path, new_relative_path)
    old_path = File.join(directory, old_relative_path)
    return unless File.directory?(old_path)

    new_path = File.join(directory, new_relative_path)
    FileUtils.mv(old_path, new_path)
  end

  def move_repositories(namespace, old_full_path, new_full_path)
    repo_paths_for_namespace(namespace).each do |repository_storage_path|
      # Ensure old directory exists before moving it
      gitlab_shell.add_namespace(repository_storage_path, old_full_path)

      unless gitlab_shell.mv_namespace(repository_storage_path, old_full_path, new_full_path)
        say "Exception moving path #{repository_storage_path} from #{old_full_path} to #{new_full_path}"
      end
    end
  end

  def rename_path(namespace_path, path_was)
    counter = 0
    path = "#{path_was}#{counter}"

    while route_exists?(join_namespace_path(namespace_path, path))
      counter += 1
      path = "#{path_was}#{counter}"
    end

    path
  end

  def route_exists?(full_path)
    Route.where(Route.arel_table[:path].matches(full_path)).any?
  end

  def join_namespace_path(namespace_path, path)
    if namespace_path.present?
      File.join(namespace_path, path)
    else
      path
    end
  end

  def system_namespace
    @system_namespace ||= Namespace.where(parent_id: nil).
                            where(arel_table[:path].matches(system_namespace_path)).
                            first
  end

  def system_namespace_path
    "system"
  end

  def clear_cache_for_namespace(namespace)
    project_ids = projects_for_namespace(namespace).pluck(:id)

    update_column_in_batches(:projects, :description_html, nil) do |table, query|
      query.where(table[:id].in(project_ids))
    end

    update_column_in_batches(:issues, :description_html, nil) do |table, query|
      query.where(table[:project_id].in(project_ids))
    end

    update_column_in_batches(:merge_requests, :description_html, nil) do |table, query|
      query.where(table[:target_project_id].in(project_ids))
    end

    update_column_in_batches(:notes, :note_html, nil) do |table, query|
      query.where(table[:project_id].in(project_ids))
    end

    update_column_in_batches(:milestones, :description_html, nil) do |table, query|
      query.where(table[:project_id].in(project_ids))
    end
  end

  def projects_for_namespace(namespace)
    namespace_ids = child_ids_for_parent(namespace, ids: [namespace.id])
    namespace_or_children = Project.arel_table[:namespace_id].in(namespace_ids)
    Project.unscoped.where(namespace_or_children)
  end

  # This won't scale to huge trees, but it should do for a handful of namespaces
  # called `system`.
  def child_ids_for_parent(namespace, ids: [])
    namespace.children.each do |child|
      ids << child.id
      child_ids_for_parent(child, ids: ids) if child.children.any?
    end
    ids
  end

  def repo_paths_for_namespace(namespace)
    projects_for_namespace(namespace).distinct.
      select(:repository_storage).map(&:repository_storage_path)
  end

  def uploads_dir
    File.join(Rails.root, "public", "uploads")
  end

  def pages_dir
    Settings.pages.path
  end

  def file_storage?
    CarrierWave::Uploader::Base.storage == CarrierWave::Storage::File
  end

  def arel_table
    Namespace.arel_table
  end
end

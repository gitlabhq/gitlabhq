class RemoveDotAtomPathEndingOfProjects < ActiveRecord::Migration
  include Gitlab::ShellAdapter

  class ProjectPath
    attr_reader :old_path, :id, :namespace_path

    def initialize(old_path, id, namespace_path, namespace_id)
      @old_path = old_path
      @id = id
      @namespace_path = namespace_path
      @namespace_id = namespace_id
    end

    def clean_path
      @_clean_path ||= PathCleaner.clean(@old_path, @namespace_id)
    end
  end

  class PathCleaner
    def initialize(path, namespace_id)
      @namespace_id = namespace_id
      @path = path
    end

    def self.clean(*args)
      new(*args).clean
    end

    def clean
      path = cleaned_path
      count = 0
      while path_exists?(path)
        path = "#{cleaned_path}#{count}"
        count += 1
      end
      path
    end

    private

    def cleaned_path
      @_cleaned_path ||= @path.gsub(/\.atom\z/, '-atom')
    end

    def path_exists?(path)
      Project.find_by_path_and_namespace_id(path, @namespace_id)
    end
  end

  def projects_with_dot_atom
    select_all("SELECT p.id, p.path, n.path as namespace_path, n.id as namespace_id FROM projects p inner join namespaces n on n.id = p.namespace_id WHERE p.path LIKE '%.atom'")
  end

  def up
    projects_with_dot_atom.each do |project|
      project_path = ProjectPath.new(project['path'], project['id'], project['namespace_path'], project['namespace_id'])
      clean_path(project_path) if rename_project_repo(project_path)
    end
  end

  private

  def clean_path(project_path)
    execute "UPDATE projects SET path = #{sanitize(project_path.clean_path)} WHERE id = #{project_path.id}"
  end

  def rename_project_repo(project_path)
    old_path_with_namespace = File.join(project_path.namespace_path, project_path.old_path)
    new_path_with_namespace = File.join(project_path.namespace_path, project_path.clean_path)

    gitlab_shell.mv_repository("#{old_path_with_namespace}.wiki", "#{new_path_with_namespace}.wiki")
    gitlab_shell.mv_repository(old_path_with_namespace, new_path_with_namespace)
  rescue
    false
  end

  def sanitize(value)
    ActiveRecord::Base.connection.quote(value)
  end
end

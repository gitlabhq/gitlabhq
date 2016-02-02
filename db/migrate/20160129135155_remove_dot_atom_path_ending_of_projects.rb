class RemoveDotAtomPathEndingOfProjects < ActiveRecord::Migration
  include Gitlab::ShellAdapter

  class ProjectPath
    attr_reader :old_path, :id, :namespace_path

    def initialize(old_path, id, namespace_path)
      @old_path = old_path
      @id = id
      @namespace_path = namespace_path
    end

    def clean_path
      @_clean_path ||= PathCleaner.clean(@old_path)
    end
  end

  class PathCleaner
    def initialize(path)
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

    def cleaned_path
      @_cleaned_path ||= @path.gsub(/\.atom\z/, '-atom')
    end

    def path_exists?(path)
      Project.find_by_path(path)
    end
  end

  def projects_with_dot_atom
    select_all("SELECT p.id, p.path, n.path as namespace_path FROM projects p inner join namespaces n on n.id = p.namespace_id WHERE lower(p.path) LIKE '%.atom'")
  end

  def up
    projects_with_dot_atom.each do |project|
      project_path = ProjectPath.new(project['path'], project['id'], project['namespace_path'])
      clean_path(project_path) if rename_project_repo(project_path)
    end
  end

  private

  def clean_path(project_path)
    execute "UPDATE projects SET path = '#{project_path.clean_path}' WHERE id = #{project_path.id}"
  end

  def rename_project_repo(project_path)
    old_path_with_namespace = File.join(project_path.namespace_path, project_path.old_path)
    new_path_with_namespace = File.join(project_path.namespace_path, project_path.clean_path)

    gitlab_shell.mv_repository("#{old_path_with_namespace}.wiki", "#{new_path_with_namespace}.wiki")
    gitlab_shell.mv_repository(old_path_with_namespace, new_path_with_namespace)
  end
end

module Gitlab
  class ProjectRepoPath
    attr_reader :group_path, :project_name, :repo_path

    def initialize(root_path, repo_path)
      @root_path = root_path
      @repo_path = repo_path

      # Split path into 'all/the/namespaces' and 'project_name'
      @group_path, _sep, @project_name = repo_relative_path.rpartition('/')
    end

    def wiki?
      @wiki ||= @repo_path.end_with?('.wiki.git')
    end

    def project_full_path
      @project_full_path ||= "#{group_path}/#{project_name}"
    end

    private

    def repo_relative_path
      # Remove root path and `.git` at the end
      repo_path.sub(/\A#{@root_path}\//, '').sub(/\.git$/, '')
    end
  end
end

module Gitlab
  module RepoPath
    NotFoundError = Class.new(StandardError)

    def self.parse(repo_path)
      project_path = strip_storage_path(repo_path.sub(/\.git\z/, ''), fail_on_not_found: false)
      project = Project.find_by_full_path(project_path)
      if project_path.end_with?('.wiki') && !project
        project = Project.find_by_full_path(project_path.chomp('.wiki'))
        wiki = true
      else
        wiki = false
      end

      [project, wiki]
    end

    def self.strip_storage_path(repo_path, fail_on_not_found: true)
      result = repo_path

      storage = Gitlab.config.repositories.storages.values.find do |params|
        repo_path.start_with?(params['path'])
      end

      if storage
        result = result.sub(storage['path'], '')
      elsif fail_on_not_found
        raise NotFoundError.new("No known storage path matches #{repo_path.inspect}")
      end

      result.sub(/\A\/*/, '')
    end
  end
end

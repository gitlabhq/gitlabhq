module Gitlab
  module RepoPath
    NotFoundError = Class.new(StandardError)

    def self.parse(repo_path)
      wiki = false
      project_path = strip_storage_path(repo_path.sub(/\.git\z/, ''), fail_on_not_found: false)
      project, was_redirected = find_project(project_path)

      if project_path.end_with?('.wiki') && project.nil?
        project, was_redirected = find_project(project_path.chomp('.wiki'))
        wiki = true
      end

      redirected_path = project_path if was_redirected

      [project, wiki, redirected_path]
    end

    def self.strip_storage_path(repo_path, fail_on_not_found: true)
      result = repo_path

      storage = Gitlab.config.repositories.storages.values.find do |params|
        repo_path.start_with?(params.legacy_disk_path)
      end

      if storage
        result = result.sub(storage.legacy_disk_path, '')
      elsif fail_on_not_found
        raise NotFoundError.new("No known storage path matches #{repo_path.inspect}")
      end

      result.sub(%r{\A/*}, '')
    end

    def self.find_project(project_path)
      project = Project.find_by_full_path(project_path, follow_redirects: true)
      was_redirected = project && project.full_path.casecmp(project_path) != 0

      [project, was_redirected]
    end
  end
end

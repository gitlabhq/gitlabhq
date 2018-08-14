module Gitlab
  module RepoPath
    NotFoundError = Class.new(StandardError)

    def self.parse(repo_path)
      wiki = false
      project_path = repo_path.sub(/\.git\z/, '').sub(%r{\A/}, '')

      project, was_redirected = find_project(project_path)

      if project_path.end_with?('.wiki') && project.nil?
        project, was_redirected = find_project(project_path.chomp('.wiki'))
        wiki = true
      end

      redirected_path = project_path if was_redirected

      [project, wiki, redirected_path]
    end

    def self.find_project(project_path)
      project = Project.find_by_full_path(project_path, follow_redirects: true)
      was_redirected = project && project.full_path.casecmp(project_path) != 0

      [project, was_redirected]
    end
  end
end

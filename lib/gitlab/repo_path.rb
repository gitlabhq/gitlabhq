# frozen_string_literal: true

module Gitlab
  module RepoPath
    NotFoundError = Class.new(StandardError)

    def self.parse(repo_path)
      project_path = repo_path.sub(/\.git\z/, '').sub(%r{\A/}, '')

      # Detect the repo type based on the path, the first one tried is the project
      # type, which does not have a suffix.
      Gitlab::GlRepository.types.each do |_name, type|
        # If the project path does not end with the defined suffix, try the next
        # type.
        # We'll always try to find a project with an empty suffix (for the
        # `Gitlab::GlRepository::PROJECT` type.
        next unless project_path.end_with?(type.path_suffix)

        project, was_redirected = find_project(project_path.chomp(type.path_suffix))
        redirected_path = project_path if was_redirected

        # If we found a matching project, then the type was matched, no need to
        # continue looking.
        return [project, type, redirected_path] if project
      end

      nil
    end

    def self.find_project(project_path)
      project = Project.find_by_full_path(project_path, follow_redirects: true)
      was_redirected = project && project.full_path.casecmp(project_path) != 0

      [project, was_redirected]
    end
  end
end

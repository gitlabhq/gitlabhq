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

      # When a project did not exist, the parsed repo_type would be empty.
      # In that case, we want to continue with a regular project repository. As we
      # could create the project if the user pushing is allowed to do so.
      [nil, Gitlab::GlRepository.default_type, nil]
    end

    def self.find_project(project_path)
      project = Project.find_by_full_path(project_path, follow_redirects: true)

      [project, redirected?(project, project_path)]
    end

    def self.redirected?(project, project_path)
      project && project.full_path.casecmp(project_path) != 0
    end
  end
end

Gitlab::RepoPath.singleton_class.prepend_if_ee('EE::Gitlab::RepoPath::ClassMethods')

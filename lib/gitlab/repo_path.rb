# frozen_string_literal: true

module Gitlab
  module RepoPath
    NotFoundError = Class.new(StandardError)

    # Returns an array containing:
    # - The repository container
    # - The related project (if available)
    # - The repository type
    # - The original container path (if redirected)
    #
    # @returns [HasRepository, Project, String, String]
    def self.parse(path)
      repo_path = path.delete_prefix('/').delete_suffix('.git')

      # Detect the repo type based on the path, the first one tried is the project
      # type, which does not have a suffix.
      Gitlab::GlRepository.types.each do |_name, type|
        # If the project path does not end with the defined suffix, try the next
        # type.
        # We'll always try to find a project with an empty suffix (for the
        # `Gitlab::GlRepository::PROJECT` type.
        next unless type.valid?(repo_path)

        # Removing the suffix (.wiki, .design, ...) from the project path
        full_path = repo_path.chomp(type.path_suffix)
        container, project = find_container(type, full_path)
        next unless container

        redirected_path = repo_path if redirected?(container, repo_path)
        return [container, project, type, redirected_path]
      end

      # When a project did not exist, the parsed repo_type would be empty.
      # In that case, we want to continue with a regular project repository. As we
      # could create the project if the user pushing is allowed to do so.
      [nil, nil, Gitlab::GlRepository.default_type, nil]
    end

    # Returns an array containing:
    # - The repository container
    # - The related project (if available)
    #
    # @returns [HasRepository, Project, String]
    def self.find_container(type, full_path)
      return [nil, nil] if full_path.blank?

      if type.snippet?
        snippet = find_snippet(full_path)

        [snippet, snippet&.project]
      elsif type.wiki?
        wiki = find_wiki(full_path)

        [wiki, wiki.try(:project)]
      elsif type.design?
        design_management_repository = find_design_management_repository(full_path)

        [design_management_repository, design_management_repository.project]
      else
        project = find_project(full_path)

        [project, project]
      end
    end

    def self.find_project(project_path)
      Project.find_by_full_path(project_path, follow_redirects: true)
    end

    def self.redirected?(container, container_path)
      container && container.full_path.casecmp(container_path) != 0
    end

    # Snippet_path can be either:
    # - snippets/1
    # - h5bp/html5-boilerplate/snippets/53
    def self.find_snippet(snippet_path)
      snippet_id, project_path = extract_snippet_info(snippet_path)
      return unless snippet_id

      project = find_project(project_path) if project_path

      Snippet.find_by_id_and_project(id: snippet_id, project: project)
    end

    # Wiki path can be either:
    # - namespace/project
    # - group/subgroup/project
    #
    # And also in EE:
    # - group
    # - group/subgroup
    def self.find_wiki(container_path)
      container = Routable.find_by_full_path(container_path, follow_redirects: true)

      # In CE, Group#wiki is not available so this will return nil for a group path.
      container&.try(:wiki)
    end

    def self.find_design_management_repository(full_path)
      find_project(full_path)&.design_management_repository
    end

    def self.extract_snippet_info(snippet_path)
      path_segments = snippet_path.split('/')
      snippet_id = path_segments.pop
      path_segments.pop # Remove 'snippets' from path
      project_path = File.join(path_segments).presence

      [snippet_id, project_path]
    end
  end
end

Gitlab::RepoPath.singleton_class.prepend_mod_with('Gitlab::RepoPath::ClassMethods')

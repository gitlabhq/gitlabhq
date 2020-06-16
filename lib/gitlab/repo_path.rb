# frozen_string_literal: true

module Gitlab
  module RepoPath
    NotFoundError = Class.new(StandardError)

    # @return [Array]
    #   1. container (ActiveRecord which holds repository)
    #   2. project (Project)
    #   3. repo_type
    #   4. redirected_path
    def self.parse(path)
      repo_path = path.sub(/\.git\z/, '').sub(%r{\A/}, '')
      redirected_path = nil

      # Detect the repo type based on the path, the first one tried is the project
      # type, which does not have a suffix.
      Gitlab::GlRepository.types.each do |_name, type|
        # If the project path does not end with the defined suffix, try the next
        # type.
        # We'll always try to find a project with an empty suffix (for the
        # `Gitlab::GlRepository::PROJECT` type.
        next unless type.valid?(repo_path)

        # Removing the suffix (.wiki, .design, ...) from path
        full_path = repo_path.chomp(type.path_suffix)
        container, project, redirected_path = find_container(type, full_path)

        return [container, project, type, redirected_path] if container
      end

      # When a project did not exist, the parsed repo_type would be empty.
      # In that case, we want to continue with a regular project repository. As we
      # could create the project if the user pushing is allowed to do so.
      [nil, nil, Gitlab::GlRepository.default_type, nil]
    end

    def self.find_container(type, full_path)
      if type.snippet?
        snippet, redirected_path = find_snippet(full_path)

        [snippet, snippet&.project, redirected_path]
      else
        container, redirected_path = find_routes_source(full_path)

        if container.is_a?(Project)
          [container, container, redirected_path]
        else
          [container, nil, redirected_path]
        end
      end
    end

    def self.find_routes_source(path)
      return [nil, nil] if path.blank?

      source =
        Route.find_source_of_path(path) ||
        Route.find_source_of_path(path, case_sensitive: false) ||
        RedirectRoute.find_source_of_path(path, case_sensitive: false)

      redirected_path = redirected?(source, path) ? path : nil

      [source, redirected_path]
    end

    def self.redirected?(container, container_path)
      container && container.full_path.casecmp(container_path) != 0
    end

    # Snippet_path can be either:
    # - snippets/1
    # - h5bp/html5-boilerplate/snippets/53
    def self.find_snippet(snippet_path)
      return [nil, nil] if snippet_path.blank?

      snippet_id, project_path = extract_snippet_info(snippet_path)
      project, redirected_path = find_routes_source(project_path)

      [Snippet.find_by_id_and_project(id: snippet_id, project: project), redirected_path]
    end

    def self.extract_snippet_info(snippet_path)
      path_segments = snippet_path.split('/')
      snippet_id = path_segments.pop
      path_segments.pop # Remove snippets from path
      project_path = File.join(path_segments)

      [snippet_id, project_path]
    end
  end
end

Gitlab::RepoPath.singleton_class.prepend_if_ee('EE::Gitlab::RepoPath::ClassMethods')

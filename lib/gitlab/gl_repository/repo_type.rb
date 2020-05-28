# frozen_string_literal: true

module Gitlab
  class GlRepository
    class RepoType
      attr_reader :name,
                  :access_checker_class,
                  :repository_resolver,
                  :container_class,
                  :project_resolver,
                  :guest_read_ability,
                  :suffix

      def initialize(
        name:,
        access_checker_class:,
        repository_resolver:,
        container_class: default_container_class,
        project_resolver: nil,
        guest_read_ability: :download_code,
        suffix: nil)
        @name = name
        @access_checker_class = access_checker_class
        @repository_resolver = repository_resolver
        @container_class = container_class
        @project_resolver = project_resolver
        @guest_read_ability = guest_read_ability
        @suffix = suffix
      end

      def identifier_for_container(container)
        if container.is_a?(Group)
          return "#{container.class.name.underscore}-#{container.id}-#{name}"
        end

        "#{name}-#{container.id}"
      end

      def wiki?
        self == WIKI
      end

      def project?
        self == PROJECT
      end

      def snippet?
        self == SNIPPET
      end

      def design?
        self == DESIGN
      end

      def path_suffix
        suffix ? ".#{suffix}" : ''
      end

      def repository_for(container)
        repository_resolver.call(container)
      end

      def project_for(container)
        return container unless project_resolver

        project_resolver.call(container)
      end

      def valid?(repository_path)
        repository_path.end_with?(path_suffix) &&
        (
          !snippet? ||
          repository_path.match?(Gitlab::PathRegex.full_snippets_repository_path_regex)
        )
      end

      private

      def default_container_class
        Project
      end
    end
  end
end

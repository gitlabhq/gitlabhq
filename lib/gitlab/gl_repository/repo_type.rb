# frozen_string_literal: true

module Gitlab
  class GlRepository
    class RepoType
      attr_reader :name,
                  :access_checker_class,
                  :repository_resolver,
                  :container_resolver,
                  :project_resolver,
                  :guest_read_ability,
                  :suffix

      def initialize(
        name:,
        access_checker_class:,
        repository_resolver:,
        container_resolver: default_container_resolver,
        project_resolver: nil,
        guest_read_ability: :download_code,
        suffix: nil)
        @name = name
        @access_checker_class = access_checker_class
        @repository_resolver = repository_resolver
        @container_resolver = container_resolver
        @project_resolver = project_resolver
        @guest_read_ability = guest_read_ability
        @suffix = suffix
      end

      def identifier_for_container(container)
        "#{name}-#{container.id}"
      end

      def fetch_id(identifier)
        match = /\A#{name}-(?<id>\d+)\z/.match(identifier)
        match[:id] if match
      end

      def fetch_container!(identifier)
        id = fetch_id(identifier)

        raise ArgumentError, "Invalid GL Repository \"#{identifier}\"" unless id

        container_resolver.call(id)
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

      def default_container_resolver
        -> (id) { Project.find_by_id(id) }
      end
    end
  end
end

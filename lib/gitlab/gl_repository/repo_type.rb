# frozen_string_literal: true

module Gitlab
  class GlRepository
    class RepoType
      attr_reader :name,
                  :access_checker_class,
                  :repository_resolver,
                  :container_resolver,
                  :suffix

      def initialize(
        name:,
        access_checker_class:,
        repository_resolver:,
        container_resolver: default_container_resolver,
        suffix: nil)
        @name = name
        @access_checker_class = access_checker_class
        @repository_resolver = repository_resolver
        @container_resolver = container_resolver
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

      def path_suffix
        suffix ? ".#{suffix}" : ''
      end

      def repository_for(container)
        repository_resolver.call(container)
      end

      def valid?(repository_path)
        repository_path.end_with?(path_suffix)
      end

      private

      def default_container_resolver
        -> (id) { Project.find_by_id(id) }
      end
    end
  end
end

Gitlab::GlRepository::RepoType.prepend_if_ee('EE::Gitlab::GlRepository::RepoType')

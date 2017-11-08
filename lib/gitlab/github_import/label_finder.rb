# frozen_string_literal: true

module Gitlab
  module GithubImport
    class LabelFinder
      attr_reader :project

      # The base cache key to use for storing/retrieving label IDs.
      CACHE_KEY = 'github-import/label-finder/%{project}/%{name}'.freeze

      # project - An instance of `Project`.
      def initialize(project)
        @project = project
      end

      # Returns the label ID for the given name.
      def id_for(name)
        Caching.read_integer(cache_key_for(name))
      end

      def build_cache
        mapping = @project
          .labels
          .pluck(:id, :name)
          .each_with_object({}) do |(id, name), hash|
            hash[cache_key_for(name)] = id
          end

        Caching.write_multiple(mapping)
      end

      def cache_key_for(name)
        CACHE_KEY % { project: project.id, name: name }
      end
    end
  end
end

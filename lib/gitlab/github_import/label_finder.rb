# frozen_string_literal: true

module Gitlab
  module GithubImport
    class LabelFinder
      attr_reader :project

      # The base cache key to use for storing/retrieving label IDs.
      CACHE_KEY = 'github-import/label-finder/%{project}/%{name}'
      CACHE_OBJECT_NOT_FOUND = -1

      # project - An instance of `Project`.
      def initialize(project)
        @project = project
      end

      # Returns the label ID for the given name.
      def id_for(name)
        cache_key = cache_key_for(name)
        val = Gitlab::Cache::Import::Caching.read_integer(cache_key)

        return if val == CACHE_OBJECT_NOT_FOUND
        return val if val.present?

        object_id = project.labels.with_title(name).pick(:id) || CACHE_OBJECT_NOT_FOUND

        Gitlab::Cache::Import::Caching.write(cache_key, object_id)
        object_id == CACHE_OBJECT_NOT_FOUND ? nil : object_id
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def build_cache
        mapping = @project
          .labels
          .pluck(:id, :name)
          .each_with_object({}) do |(id, name), hash|
            hash[cache_key_for(name)] = id
          end

        Gitlab::Cache::Import::Caching.write_multiple(mapping)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def cache_key_for(name)
        format(CACHE_KEY, project: project.id, name: name)
      end
    end
  end
end

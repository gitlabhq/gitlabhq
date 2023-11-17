# frozen_string_literal: true

module Gitlab
  module GithubImport
    class MilestoneFinder
      attr_reader :project

      # The base cache key to use for storing/retrieving milestone IDs.
      CACHE_KEY = 'github-import/milestone-finder/%{project}/%{iid}'
      CACHE_OBJECT_NOT_FOUND = -1

      # project - An instance of `Project`
      def initialize(project)
        @project = project
      end

      # issuable - An instance of `Gitlab::GithubImport::Representation::Issue`
      #            or `Gitlab::GithubImport::Representation::PullRequest`.
      def id_for(issuable)
        return unless issuable.milestone_number

        milestone_iid = issuable.milestone_number
        cache_key = cache_key_for(milestone_iid)

        val = Gitlab::Cache::Import::Caching.read_integer(cache_key)

        return if val == CACHE_OBJECT_NOT_FOUND
        return val if val.present?

        object_id = project.milestones.by_iid(milestone_iid).pick(:id) || CACHE_OBJECT_NOT_FOUND

        Gitlab::Cache::Import::Caching.write(cache_key, object_id)
        object_id == CACHE_OBJECT_NOT_FOUND ? nil : object_id
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def build_cache
        mapping = @project
          .milestones
          .pluck(:id, :iid)
          .each_with_object({}) do |(id, iid), hash|
            hash[cache_key_for(iid)] = id
          end

        Gitlab::Cache::Import::Caching.write_multiple(mapping)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def cache_key_for(iid)
        format(CACHE_KEY, project: project.id, iid: iid)
      end
    end
  end
end

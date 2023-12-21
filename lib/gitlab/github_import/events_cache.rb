# frozen_string_literal: true

module Gitlab
  module GithubImport
    class EventsCache
      MAX_NUMBER_OF_EVENTS = 100
      MAX_EVENT_SIZE = 100.kilobytes

      def initialize(project)
        @project = project
      end

      # Add issue event as JSON to the cache
      #
      # @param record [ActiveRecord::Model] Model that responds to :iid
      # @param event [GitLab::GitHubImport::Representation::IssueEvent]
      def add(record, issue_event)
        json = issue_event.to_hash.to_json

        if json.bytesize > MAX_EVENT_SIZE
          Logger.warn(
            message: 'Event too large to cache',
            project_id: project.id,
            github_identifiers: issue_event.github_identifiers
          )

          return
        end

        Gitlab::Cache::Import::Caching.list_add(events_cache_key(record), json, limit: MAX_NUMBER_OF_EVENTS)
      end

      # Reads issue events from cache
      #
      # @param record [ActiveRecord::Model] Model that responds to :iid
      # @retun [Array<GitLab::GitHubImport::Representation::IssueEvent>] List of issue events
      def events(record)
        events = Gitlab::Cache::Import::Caching.values_from_list(events_cache_key(record)).map do |event|
          Representation::IssueEvent.from_json_hash(Gitlab::Json.parse(event))
        end

        events.sort_by(&:created_at)
      end

      # Deletes the cache
      #
      # @param record [ActiveRecord::Model] Model that responds to :iid
      def delete(record)
        Gitlab::Cache::Import::Caching.del(events_cache_key(record))
      end

      private

      attr_reader :project

      def events_cache_key(record)
        "github-importer/events/#{project.id}/#{record.class.name}/#{record.iid}"
      end
    end
  end
end

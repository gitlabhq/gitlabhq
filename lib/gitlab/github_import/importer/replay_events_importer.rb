# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class ReplayEventsImporter
        SUPPORTED_EVENTS = %w[review_request_removed review_requested].freeze

        # replay_event - An instance of `Gitlab::GithubImport::Representation::ReplayEvent`.
        # project - An instance of `Project`
        # client - An instance of `Gitlab::GithubImport::Client`
        def initialize(replay_event, project, client)
          @project = project
          @client = client
          @replay_event = replay_event
        end

        def execute
          association = case replay_event.issuable_type
                        when 'MergeRequest'
                          project.merge_requests.find_by_iid(replay_event.issuable_iid)
                        end

          return unless association

          events_cache = EventsCache.new(project)

          handle_review_requests(association, events_cache.events(association))

          events_cache.delete(association)
        end

        private

        attr_reader :project, :client, :replay_event

        def handle_review_requests(association, events)
          reviewers = {}

          events.each do |event|
            case event.event
            when 'review_requested'
              reviewers[event.requested_reviewer.login] = event.requested_reviewer.to_hash if event.requested_reviewer
            when 'review_request_removed'
              reviewers[event.requested_reviewer.login] = nil if event.requested_reviewer
            end
          end

          representation = Representation::PullRequests::ReviewRequests.from_json_hash(
            merge_request_id: association.id,
            merge_request_iid: association.iid,
            users: reviewers.values.compact
          )

          Importer::PullRequests::ReviewRequestImporter.new(representation, project, client).execute
        end
      end
    end
  end
end

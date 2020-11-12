# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    module TrackUniqueEvents
      WIKI_ACTION = :wiki_action
      DESIGN_ACTION = :design_action
      PUSH_ACTION = :project_action
      MERGE_REQUEST_ACTION = :merge_request_action

      GIT_WRITE_ACTIONS = [WIKI_ACTION, DESIGN_ACTION, PUSH_ACTION].freeze
      GIT_WRITE_ACTION = :git_write_action

      ACTION_TRANSFORMATIONS = HashWithIndifferentAccess.new({
        wiki: {
          created: WIKI_ACTION,
          updated: WIKI_ACTION,
          destroyed: WIKI_ACTION
        },
        design: {
          created: DESIGN_ACTION,
          updated: DESIGN_ACTION,
          destroyed: DESIGN_ACTION
        },
        project: {
          pushed: PUSH_ACTION
        },
        merge_request: {
          closed: MERGE_REQUEST_ACTION,
          merged: MERGE_REQUEST_ACTION,
          created: MERGE_REQUEST_ACTION,
          commented: MERGE_REQUEST_ACTION
        }
      }).freeze

      class << self
        def track_event(event_action:, event_target:, author_id:, time: Time.zone.now)
          return unless valid_target?(event_target)
          return unless valid_action?(event_action)

          transformed_target = transform_target(event_target)
          transformed_action = transform_action(event_action, transformed_target)

          return unless Gitlab::UsageDataCounters::HLLRedisCounter.known_event?(transformed_action.to_s)

          Gitlab::UsageDataCounters::HLLRedisCounter.track_event(author_id, transformed_action.to_s, time)

          track_git_write_action(author_id, transformed_action, time)
        end

        def count_unique_events(event_action:, date_from:, date_to:)
          Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(event_names: event_action.to_s, start_date: date_from, end_date: date_to)
        end

        private

        def transform_action(event_action, event_target)
          ACTION_TRANSFORMATIONS.dig(event_target, event_action) || event_action
        end

        def transform_target(event_target)
          Event::TARGET_TYPES.key(event_target)
        end

        def valid_target?(target)
          Event::TARGET_TYPES.value?(target)
        end

        def valid_action?(action)
          Event.actions.key?(action)
        end

        def track_git_write_action(author_id, transformed_action, time)
          return unless GIT_WRITE_ACTIONS.include?(transformed_action)

          Gitlab::UsageDataCounters::HLLRedisCounter.track_event(author_id, GIT_WRITE_ACTION, time)
        end
      end
    end
  end
end

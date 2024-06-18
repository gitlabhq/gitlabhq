# frozen_string_literal: true

module Clusters
  module AgentTokens
    class TrackUsageService
      # The `UPDATE_USED_COLUMN_EVERY` defines how often the token DB entry can be updated
      UPDATE_USED_COLUMN_EVERY = ((40.minutes)..(55.minutes))

      delegate :agent, to: :token

      def initialize(token)
        @token = token
      end

      def execute
        track_values = { last_used_at: Time.current.utc }

        token.cache_attributes(track_values)

        if can_update_track_values?
          log_activity_event!(track_values[:last_used_at]) unless agent.connected?

          # Use update_column so updated_at is skipped
          token.update_columns(track_values)
        end
      rescue StandardError => e
        Gitlab::ErrorTracking.track_exception(e, agent_id: token.agent_id)

        ServiceResponse.error(message: e.message)
      end

      private

      attr_reader :token

      def can_update_track_values?
        # Use a random threshold to prevent beating DB updates.
        last_used_at_max_age = Random.rand(UPDATE_USED_COLUMN_EVERY)

        real_last_used_at = token.read_attribute(:last_used_at)

        # Handle too many updates from high token traffic
        real_last_used_at.nil? ||
          (Time.current - real_last_used_at) >= last_used_at_max_age
      end

      def log_activity_event!(recorded_at)
        Clusters::Agents::CreateActivityEventService.new(
          agent,
          kind: :agent_connected,
          level: :info,
          recorded_at: recorded_at,
          agent_token: token
        ).execute
      end
    end
  end
end

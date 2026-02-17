# frozen_string_literal: true

module Gitlab
  module Tracking
    class AiContext
      SCHEMA_URL = 'iglu:com.gitlab/ai_context/jsonschema/1-0-0'

      def initialize(properties)
        @payload = properties&.compact || {}
      end

      def to_context
        SnowplowTracker::SelfDescribingJson.new(SCHEMA_URL, to_h)
      end

      def to_h
        {
          session_id: payload[:session_id],
          workflow_id: payload[:workflow_id],
          flow_type: payload[:flow_type],
          agent_name: payload[:agent_name],
          agent_type: payload[:agent_type],
          input_tokens: payload[:input_tokens],
          output_tokens: payload[:output_tokens],
          total_tokens: payload[:total_tokens],
          ephemeral_5m_input_tokens: payload[:ephemeral_5m_input_tokens],
          ephemeral_1h_input_tokens: payload[:ephemeral_1h_input_tokens],
          cache_read: payload[:cache_read],
          model_engine: payload[:model_engine],
          model_name: payload[:model_name],
          model_provider: payload[:model_provider],
          flow_version: payload[:flow_version],
          flow_registry_version: payload[:flow_registry_version]
        }
      end

      private

      attr_reader :payload
    end
  end
end

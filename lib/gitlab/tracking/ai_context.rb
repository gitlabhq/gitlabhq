# frozen_string_literal: true

module Gitlab
  module Tracking
    class AiContext
      SCHEMA_URL = 'iglu:com.gitlab/ai_context/jsonschema/1-0-2'

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
          item_type: payload[:item_type],
          item_version: payload[:item_version],
          item_schema_version: payload[:item_schema_version],
          flow_name: payload[:flow_name],
          component_name: payload[:component_name],
          agent_name: payload[:agent_name],
          agent_type: payload[:agent_type],
          custom_item_id: payload[:custom_item_id],
          input_tokens: payload[:input_tokens],
          output_tokens: payload[:output_tokens],
          total_tokens: payload[:total_tokens],
          ephemeral_5m_input_tokens: payload[:ephemeral_5m_input_tokens],
          ephemeral_1h_input_tokens: payload[:ephemeral_1h_input_tokens],
          cache_read: payload[:cache_read],
          cache_creation: payload[:cache_creation],
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

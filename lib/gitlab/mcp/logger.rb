# frozen_string_literal: true

module Gitlab
  module Mcp
    class Logger < ::Gitlab::JsonLogger
      def self.file_name_noext
        'mcp'
      end

      # `expanded` carries request content (e.g. argument values) that the AI data-retention policy
      # only permits logging when expanded logging is enabled; `fields` are always safe to index.
      def conditional_info(user, message:, event_name:, ai_component:, namespace: nil, expanded: {}, **fields)
        params = {
          message: message,
          event_name: event_name,
          ai_component: ai_component,
          ::Labkit::Fields::GL_USER_ID => user&.id,
          **fields
        }
        params.merge!(expanded) if should_log_expanded?(user, namespace: namespace)

        info(params)
      end

      private

      # Expanded logging depends on EE-only settings, so CE never expands. Overridden in EE.
      def should_log_expanded?(_user, **)
        false
      end
    end
  end
end

Gitlab::Mcp::Logger.prepend_mod

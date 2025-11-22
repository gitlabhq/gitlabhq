# frozen_string_literal: true

module Gitlab
  module Tracking
    # Decorator for StandardContext that filters sensitive fields for unauthenticated frontend users.
    #
    # StandardContext contains instance-level information that is safe to send from the backend
    # to Snowplow for analytics, but some of this data should not be exposed to unauthenticated
    # users in their browser's JavaScript context.
    #
    # This class wraps StandardContext and removes sensitive fields before serialization,
    # preventing unauthenticated users from seeing information like:
    # - Instance version (could reveal security vulnerabilities)
    # - Instance IDs (internal identifiers)
    # - Host name (internal infrastructure details)
    # - Plan name (potentially sensitive business information)
    #
    # Usage:
    #   standard_ctx = Gitlab::Tracking::StandardContext.new(namespace: namespace, user: nil)
    #
    #   # Only use the decorator for unauthenticated users
    #   context = current_user ? standard_ctx : Gitlab::Tracking::FrontendStandardContext.new(standard_ctx)
    #   context.to_context # Returns filtered context for unauthenticated, full context for authenticated
    #
    class FrontendStandardContext
      SENSITIVE_FIELDS = %i[
        instance_version
        instance_id
        unique_instance_id
        host_name
        plan
      ].freeze

      def initialize(standard_context)
        @standard_context = standard_context
      end

      def to_context
        filtered_data = @standard_context.to_h.except(*SENSITIVE_FIELDS)
        SnowplowTracker::SelfDescribingJson.new(
          StandardContext::GITLAB_STANDARD_SCHEMA_URL,
          filtered_data
        )
      end
    end
  end
end

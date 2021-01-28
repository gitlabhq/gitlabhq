# frozen_string_literal: true

module Gitlab
  module Tracking
    class StandardContext
      GITLAB_STANDARD_SCHEMA_URL = 'iglu:com.gitlab/gitlab_standard/jsonschema/1-0-2'.freeze

      def initialize(namespace: nil, project: nil, user: nil, **data)
        @data = data
      end

      def to_context
        SnowplowTracker::SelfDescribingJson.new(GITLAB_STANDARD_SCHEMA_URL, to_h)
      end

      def environment
        return 'production' if Gitlab.com_and_canary?

        return 'staging' if Gitlab.staging?

        'development'
      end

      private

      def to_h
        public_methods(false).each_with_object({}) do |method, hash|
          next if method == :to_context

          hash[method] = public_send(method) # rubocop:disable GitlabSecurity/PublicSend
        end.merge(@data)
      end
    end
  end
end

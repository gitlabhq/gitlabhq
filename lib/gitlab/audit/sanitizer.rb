# frozen_string_literal: true

module Gitlab
  module Audit
    class Sanitizer
      # Maximum length for user agent field to prevent oversized rows/stream payloads
      USER_AGENT_MAX_LENGTH = 250

      # Sanitizes and truncates user agent string to prevent security issues
      # and oversized audit event payloads
      #
      # @param user_agent [String, nil] The raw user agent string from the request
      # @return [String, nil] The sanitized and truncated user agent, or nil if input is blank
      def self.sanitize_user_agent(user_agent)
        return if user_agent.blank?

        # Truncate to max length to prevent oversized rows/stream payloads
        user_agent
          .to_s
          .gsub(/[^[:print:]]/, '') # strip non-printable/control characters
          .strip
          .truncate(USER_AGENT_MAX_LENGTH, omission: '')
      end
    end
  end
end

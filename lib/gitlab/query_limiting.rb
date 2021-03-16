# frozen_string_literal: true

module Gitlab
  module QueryLimiting
    # Returns true if we should enable tracking of query counts.
    #
    # This is only enabled in development and test to ensure we don't produce
    # any errors that users of other environments can't do anything about themselves.
    def self.enabled_for_env?
      Rails.env.development? || Rails.env.test?
    end

    def self.enabled?
      enabled_for_env? &&
        !Gitlab::SafeRequestStore[:query_limiting_disabled]
    end

    # Allows the current request to execute any number of SQL queries.
    #
    # This method should _only_ be used when there's a corresponding issue to
    # reduce the number of queries.
    #
    # The issue URL is only meant to push developers into creating an issue
    # instead of blindly disabling for offending blocks of code.
    def self.disable!(issue_url)
      unless issue_url.start_with?('https://')
        raise(
          ArgumentError,
          'You must provide a valid issue URL in order to allow a block of code'
        )
      end

      Gitlab::SafeRequestStore[:query_limiting_disabled] = true
    end

    # Enables query limiting for the request.
    def self.enable!
      Gitlab::SafeRequestStore[:query_limiting_disabled] = nil
    end
  end
end

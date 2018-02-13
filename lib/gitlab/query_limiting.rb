module Gitlab
  module QueryLimiting
    # Returns true if we should enable tracking of query counts.
    #
    # This is only enabled in production/staging if we're running on GitLab.com.
    # This ensures we don't produce any errors that users can't do anything
    # about themselves.
    def self.enable?
      Rails.env.development? || Rails.env.test?
    end

    # Allows the current request to execute any number of SQL queries.
    #
    # This method should _only_ be used when there's a corresponding issue to
    # reduce the number of queries.
    #
    # The issue URL is only meant to push developers into creating an issue
    # instead of blindly whitelisting offending blocks of code.
    def self.whitelist(issue_url)
      return unless enable_whitelist?

      unless issue_url.start_with?('https://')
        raise(
          ArgumentError,
          'You must provide a valid issue URL in order to whitelist a block of code'
        )
      end

      Transaction&.current&.whitelisted = true
    end

    def self.enable_whitelist?
      Rails.env.development? || Rails.env.test?
    end
  end
end

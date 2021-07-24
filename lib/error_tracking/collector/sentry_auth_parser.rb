# frozen_string_literal: true

module ErrorTracking
  module Collector
    class SentryAuthParser
      def self.parse(request)
        # Sentry client sends auth in X-Sentry-Auth header
        #
        # Example of content:
        # "Sentry sentry_version=7, sentry_client=sentry-ruby/4.5.1, sentry_timestamp=1623923398,
        #         sentry_key=afadk312..., sentry_secret=123456asd32131..."
        auth = request.headers['X-Sentry-Auth']

        # Sentry DSN contains key and secret.
        # The key is required while secret is optional.
        # We are going to use only the key since secret is deprecated.
        public_key = auth[/sentry_key=(\w+)/, 1]

        {
          public_key: public_key
        }
      end
    end
  end
end

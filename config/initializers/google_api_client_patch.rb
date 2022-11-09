# frozen_string_literal: true

require 'google/apis/core/http_command'
require 'google/apis/version'

raise 'This patch is only tested with google-api-client-ruby v0.53.0' unless Google::Apis::VERSION == "0.53.0"

# The google-api-ruby-client does not have a way to increase or disable
# the maximum allowed time for a request to be retried. By default, it
# is using the Retriable gem's 15-minute timeout, which appears to be
# too low for uploads over 10 GB. This patches the gem with the upstream
# changes:
# https://github.com/googleapis/google-api-ruby-client/pull/8106
module Google
  module Apis
    module Core
      # Command for HTTP request/response.
      class HttpCommand
        MAX_ELAPSED_TIME = 3600

        # Execute the command, retrying as necessary
        #
        # @param [HTTPClient] client
        #   HTTP client
        # @yield [result, err] Result or error if block supplied
        # @return [Object]
        # @raise [Google::Apis::ServerError] An error occurred on the server and the request can be retried
        # @raise [Google::Apis::ClientError] The request is invalid and should not be retried without modification
        # @raise [Google::Apis::AuthorizationError] Authorization is required
        def execute(client)
          prepare!
          opencensus_begin_span
          begin
            Retriable.retriable tries: options.retries + 1,
                                max_elapsed_time: MAX_ELAPSED_TIME,
                                base_interval: 1,
                                multiplier: 2,
                                on: RETRIABLE_ERRORS do |try|
              # This 2nd level retriable only catches auth errors, and supports 1 retry, which allows
              # auth to be re-attempted without having to retry all sorts of other failures like
              # NotFound, etc
              auth_tries = (try == 1 && authorization_refreshable? ? 2 : 1)
              Retriable.retriable tries: auth_tries,
                                  on: [Google::Apis::AuthorizationError, Signet::AuthorizationError, Signet::RemoteServerError, Signet::UnexpectedStatusError],
                                  on_retry: proc { |*| refresh_authorization } do
                execute_once(client).tap do |result|
                  if block_given?
                    yield result, nil
                  end
                end
              end
            end
          rescue => e # rubocop:disable Style/RescueStandardError
            if block_given?
              yield nil, e
            else
              raise e
            end
          end
        ensure
          opencensus_end_span
          @http_res = nil
          release!
        end
      end
    end
  end
end

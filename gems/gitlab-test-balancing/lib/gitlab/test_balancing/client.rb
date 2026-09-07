# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'

module Gitlab
  module TestBalancing
    # HTTP client for the test balancing REST API.
    #
    # Talks to the `/job/test_balancing` endpoints on a GitLab instance,
    # authenticated with a CI/CD job token. A parallel job seeds the job group's
    # shared pending pool with its static test split, then repeatedly requests
    # duration-budgeted batches of test splits until the pool is drained.
    class Client
      Error = Class.new(StandardError)

      # Raised when the API responds 404, which the server returns when test
      # balancing is unavailable for the project (feature flag off or unlicensed).
      # Callers use this to fall back to a static split.
      FeatureUnavailableError = Class.new(Error)

      Result = Struct.new(:mode, :test_splits, keyword_init: true)

      OPEN_TIMEOUT = 10
      READ_TIMEOUT = 30
      MAX_ATTEMPTS = 3
      RETRY_BACKOFF = 2 # seconds, multiplied by the attempt number

      # Transient network errors worth retrying. Excludes HTTP error responses
      # (e.g. 404/422), which are not retried.
      RETRIABLE_ERRORS = [
        Net::OpenTimeout,
        Net::ReadTimeout,
        Errno::ECONNRESET,
        Errno::ECONNREFUSED,
        Errno::EHOSTUNREACH,
        Errno::ENETUNREACH,
        SocketError,
        IOError
      ].freeze

      def initialize(api_url: ENV['CI_API_V4_URL'], job_token: ENV['CI_JOB_TOKEN'], logger: nil)
        @api_url = api_url&.chomp('/')
        @job_token = job_token
        @logger = logger
      end

      # test_splits: array of { path:, expected_duration: }. expected_duration may
      # be omitted; the server defaults it. Returns a Result with mode ("seed" or
      # "retry") and the test splits the node should run first.
      def initialize_balancing(test_splits)
        response = post('initialize', { test_splits: test_splits })

        Result.new(mode: response['mode'], test_splits: symbolize_test_splits(response))
      end

      # Returns the next batch of test splits (array), empty when the queue is drained.
      def request
        symbolize_test_splits(post('request', {}))
      end

      private

      attr_reader :api_url, :job_token, :logger

      def post(action, body)
        uri = URI.parse("#{api_url}/job/test_balancing/#{action}")

        request = Net::HTTP::Post.new(uri)
        request['Content-Type'] = 'application/json'
        request['JOB-TOKEN'] = job_token
        request.body = JSON.dump(body)

        response = with_retries(action) do
          net_http_class.start(
            uri.hostname, uri.port,
            use_ssl: uri.scheme == 'https', open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT
          ) do |http|
            http.request(request)
          end
        end

        raise FeatureUnavailableError, "test balancing is unavailable (404) for #{action}" if
          response.is_a?(Net::HTTPNotFound)

        unless response.is_a?(Net::HTTPSuccess)
          raise Error, "test balancing #{action} failed: #{response.code} #{response.body}"
        end

        JSON.parse(response.body)
      end

      # Retry the HTTP request on transient network errors with linear backoff.
      # Only network-level failures are retried; HTTP error responses are handled
      # by the caller and are not retried here.
      def with_retries(action)
        attempt = 0

        begin
          attempt += 1
          yield
        rescue *RETRIABLE_ERRORS => e
          raise Error, "test balancing #{action} failed after #{MAX_ATTEMPTS} attempts: #{e.class}: #{e.message}" if
            attempt >= MAX_ATTEMPTS

          logger&.info("test balancing #{action} attempt #{attempt} failed (#{e.class}), retrying...")
          sleep(RETRY_BACKOFF * attempt)
          retry
        end
      end

      def symbolize_test_splits(response)
        Array(response['test_splits']).map { |split| split.transform_keys(&:to_sym) }
      end

      # When WebMock is loaded (e.g. the client runs inside a spec suite that
      # enabled WebMock), use the original, un-stubbed Net::HTTP it saved so our
      # own API calls hit the network without touching WebMock's global config or
      # tripping the suite's request stubs. Falls back to plain Net::HTTP when
      # WebMock is absent.
      def net_http_class
        if defined?(::WebMock::HttpLibAdapters::NetHttpAdapter::OriginalNetHTTP)
          ::WebMock::HttpLibAdapters::NetHttpAdapter::OriginalNetHTTP
        else
          Net::HTTP
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module GithubImport
    # HTTP client for interacting with the GitHub API.
    #
    # This class is basically a fancy wrapped around Octokit while adding some
    # functionality to deal with rate limiting and parallel imports. Usage is
    # mostly the same as Octokit, for example:
    #
    #     client = GithubImport::Client.new('hunter2')
    #
    #     client.labels.each do |label|
    #       puts label.name
    #     end
    class Client
      include ::Gitlab::Utils::StrongMemoize

      attr_reader :octokit

      # A single page of data and the corresponding page number.
      Page = Struct.new(:objects, :number)

      # The minimum number of requests we want to keep available.
      #
      # We don't use a value of 0 as multiple threads may be using the same
      # token in parallel. This could result in all of them hitting the GitHub
      # rate limit at once. The threshold is put in place to not hit the limit
      # in most cases.
      RATE_LIMIT_THRESHOLD = 50

      # token - The GitHub API token to use.
      #
      # per_page - The number of objects that should be displayed per page.
      #
      # parallel - When set to true hitting the rate limit will result in a
      #            dedicated error being raised. When set to `false` we will
      #            instead just `sleep()` until the rate limit is reset. Setting
      #            this value to `true` for parallel importing is crucial as
      #            otherwise hitting the rate limit will result in a thread
      #            being blocked in a `sleep()` call for up to an hour.
      def initialize(token, per_page: 100, parallel: true)
        @octokit = ::Octokit::Client.new(
          access_token: token,
          per_page: per_page,
          api_endpoint: api_endpoint
        )

        @octokit.connection_options[:ssl] = { verify: verify_ssl }

        @parallel = parallel
      end

      def parallel?
        @parallel
      end

      # Returns the details of a GitHub user.
      #
      # username - The username of the user.
      def user(username)
        with_rate_limit { octokit.user(username) }
      end

      # Returns the details of a GitHub repository.
      #
      # name - The path (in the form `owner/repository`) of the repository.
      def repository(name)
        with_rate_limit { octokit.repo(name) }
      end

      def labels(*args)
        each_object(:labels, *args)
      end

      def milestones(*args)
        each_object(:milestones, *args)
      end

      def releases(*args)
        each_object(:releases, *args)
      end

      # Fetches data from the GitHub API and yields a Page object for every page
      # of data, without loading all of them into memory.
      #
      # method - The Octokit method to use for getting the data.
      # args - Arguments to pass to the Octokit method.
      #
      # rubocop: disable GitlabSecurity/PublicSend
      def each_page(method, *args, &block)
        return to_enum(__method__, method, *args) unless block_given?

        page =
          if args.last.is_a?(Hash) && args.last[:page]
            args.last[:page]
          else
            1
          end

        collection = with_rate_limit { octokit.public_send(method, *args) }
        next_url = octokit.last_response.rels[:next]

        yield Page.new(collection, page)

        while next_url
          response = with_rate_limit { next_url.get }
          next_url = response.rels[:next]

          yield Page.new(response.data, page += 1)
        end
      end

      # Iterates over all of the objects for the given method (e.g. `:labels`).
      #
      # method - The method to send to Octokit for querying data.
      # args - Any arguments to pass to the Octokit method.
      def each_object(method, *args, &block)
        return to_enum(__method__, method, *args) unless block_given?

        each_page(method, *args) do |page|
          page.objects.each do |object|
            yield object
          end
        end
      end

      # Yields the supplied block, responding to any rate limit errors.
      #
      # The exact strategy used for handling rate limiting errors depends on
      # whether we are running in parallel mode or not. For more information see
      # `#rate_or_wait_for_rate_limit`.
      def with_rate_limit
        return yield unless rate_limiting_enabled?

        request_count_counter.increment

        raise_or_wait_for_rate_limit unless requests_remaining?

        begin
          yield
        rescue ::Octokit::TooManyRequests
          raise_or_wait_for_rate_limit

          # This retry will only happen when running in sequential mode as we'll
          # raise an error in parallel mode.
          retry
        end
      end

      # Returns `true` if we're still allowed to perform API calls.
      def requests_remaining?
        remaining_requests > RATE_LIMIT_THRESHOLD
      end

      def remaining_requests
        octokit.rate_limit.remaining
      end

      def raise_or_wait_for_rate_limit
        rate_limit_counter.increment

        if parallel?
          raise RateLimitError
        else
          sleep(rate_limit_resets_in)
        end
      end

      def rate_limit_resets_in
        # We add a few seconds to the rate limit so we don't _immediately_
        # resume when the rate limit resets as this may result in us performing
        # a request before GitHub has a chance to reset the limit.
        octokit.rate_limit.resets_in + 5
      end

      def rate_limiting_enabled?
        strong_memoize(:rate_limiting_enabled) do
          api_endpoint.include?('.github.com')
        end
      end

      def api_endpoint
        custom_api_endpoint || default_api_endpoint
      end

      def custom_api_endpoint
        github_omniauth_provider.dig('args', 'client_options', 'site')
      end

      def default_api_endpoint
        OmniAuth::Strategies::GitHub.default_options[:client_options][:site] || ::Octokit::Default.api_endpoint
      end

      def verify_ssl
        github_omniauth_provider.fetch('verify_ssl', true)
      end

      def github_omniauth_provider
        @github_omniauth_provider ||= Gitlab::Auth::OAuth::Provider.config_for('github').to_h
      end

      def rate_limit_counter
        @rate_limit_counter ||= Gitlab::Metrics.counter(
          :github_importer_rate_limit_hits,
          'The number of times we hit the GitHub rate limit when importing projects'
        )
      end

      def request_count_counter
        @request_counter ||= Gitlab::Metrics.counter(
          :github_importer_request_count,
          'The number of GitHub API calls performed when importing projects'
        )
      end
    end
  end
end

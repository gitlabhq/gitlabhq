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
      include ::Gitlab::GithubImport::Clients::SearchRepos

      attr_reader :octokit

      SEARCH_MAX_REQUESTS_PER_MINUTE = 30
      DEFAULT_PER_PAGE = 100
      CLIENT_CONNECTION_ERROR = ::Faraday::ConnectionFailed # used/set in sawyer agent which octokit uses

      # A single page of data and the corresponding URL.
      Page = Struct.new(:objects, :url)

      # The minimum number of requests we want to keep available.
      #
      # We don't use a value of 0 as multiple threads may be using the same
      # token in parallel. This could result in all of them hitting the GitHub
      # rate limit at once. The threshold is put in place to not hit the limit
      # in most cases.
      RATE_LIMIT_THRESHOLD = 50
      SEARCH_RATE_LIMIT_THRESHOLD = 3

      # token - The GitHub API token to use.
      #
      # host - The GitHub hostname. If nil, github.com will be used.
      #
      # per_page - The number of objects that should be displayed per page.
      #
      # parallel - When set to true hitting the rate limit will result in a
      #            dedicated error being raised. When set to `false` we will
      #            instead just `sleep()` until the rate limit is reset. Setting
      #            this value to `true` for parallel importing is crucial as
      #            otherwise hitting the rate limit will result in a thread
      #            being blocked in a `sleep()` call for up to an hour.
      def initialize(token, host: nil, per_page: DEFAULT_PER_PAGE, parallel: true)
        @host = host
        @octokit = ::Octokit::Client.new(
          access_token: token,
          per_page: per_page,
          api_endpoint: api_endpoint,
          web_endpoint: web_endpoint
        )

        @octokit.connection_options[:ssl] = { verify: verify_ssl }

        @parallel = parallel
      end

      def parallel?
        @parallel
      end

      # Returns the details of a GitHub user.
      # 304 (Not Modified) status means the user is cached - API won't return user data.
      #
      # @param username[String] the username of the user.
      # @param options[Hash] the optional parameters.
      def user(username, options = {})
        with_rate_limit do
          user = octokit.user(username, options)

          next if octokit.last_response&.status == 304

          user.to_h
        end
      end

      def pull_request_reviews(repo_name, iid)
        each_object(:pull_request_reviews, repo_name, iid)
      end

      def pull_request_review_requests(repo_name, iid)
        with_rate_limit { octokit.pull_request_review_requests(repo_name, iid).to_h }
      end

      def repos(options = {})
        octokit.repos(nil, options).map(&:to_h)
      end

      # Returns the details of a GitHub repository.
      #
      # name - The path (in the form `owner/repository`) of the repository.
      def repository(name)
        with_rate_limit { octokit.repo(name).to_h }
      end

      def pull_request(repo_name, iid)
        with_rate_limit { octokit.pull_request(repo_name, iid).to_h }
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

      def branches(*args)
        each_object(:branches, *args)
      end

      def collaborators(*args)
        each_object(:collaborators, *args)
      end

      def branch_protection(repo_name, branch_name)
        with_rate_limit { octokit.branch_protection(repo_name, branch_name).to_h }
      end

      # Fetches data from the GitHub API and yields a Page object for every page
      # of data, without loading all of them into memory.
      #
      # @param method [Symbol] The Octokit method to use for getting the data
      # @param resume_url [String, nil] The GitHub link header URL to resume pagination.
      #   When nil, the method will be invoked from the first page
      # @param args [Array] Arguments to pass to the Octokit method
      # @yield [Page] Each page of data from the API
      # @return [Enumerator] When no block is given
      #
      # rubocop: disable GitlabSecurity/PublicSend
      def each_page(method, resume_url, *args, &block)
        return to_enum(__method__, method, resume_url, *args) unless block

        collection = with_rate_limit do
          if resume_url.present?
            octokit.get(resume_url)
          else
            octokit.public_send(method, *args)
          end
        end

        yield Page.new(collection, resume_url)

        next_page = octokit.last_response.rels[:next]

        while next_page
          raise Exceptions::InvalidURLError, 'Invalid pagination URL' unless valid_next_url?(next_page.href)

          response = with_rate_limit { next_page.get }

          yield Page.new(response.data, next_page.href)

          next_page = response.rels[:next]
        end
      end

      # Iterates over all of the objects for the given method (e.g. `:labels`).
      #
      # method - The method to send to Octokit for querying data.
      # args - Any arguments to pass to the Octokit method.
      def each_object(method, *args, &block)
        return to_enum(__method__, method, *args) unless block

        each_page(method, nil, *args) do |page|
          page.objects.each do |object|
            yield object.to_h
          end
        end
      end

      # Yields the supplied block, responding to any rate limit errors.
      #
      # The exact strategy used for handling rate limiting errors depends on
      # whether we are running in parallel mode or not. For more information see
      # `#rate_or_wait_for_rate_limit`.
      def with_rate_limit
        return with_retry { yield } unless rate_limiting_enabled?

        request_count_counter.increment

        raise_or_wait_for_rate_limit('Internal threshold reached') unless requests_remaining?

        begin
          with_retry { yield }
        rescue ::Octokit::TooManyRequests => e
          raise_or_wait_for_rate_limit(e.response_body)

          # This retry will only happen when running in sequential mode as we'll
          # raise an error in parallel mode.
          retry
        end
      end

      # Returns `true` if we're still allowed to perform API calls.
      # Search API has rate limit of 30, use lowered threshold when search is used.
      def requests_remaining?
        if requests_limit == SEARCH_MAX_REQUESTS_PER_MINUTE
          return remaining_requests > SEARCH_RATE_LIMIT_THRESHOLD
        end

        remaining_requests > RATE_LIMIT_THRESHOLD
      end

      def remaining_requests
        octokit.rate_limit.remaining
      end

      def requests_limit
        octokit.rate_limit.limit
      end

      def raise_or_wait_for_rate_limit(message)
        rate_limit_counter.increment

        if parallel?
          raise RateLimitError, message
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
        formatted_host || custom_api_endpoint || default_api_endpoint
      end

      def web_endpoint
        formatted_host || custom_api_endpoint || ::Octokit::Default.web_endpoint
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

      private

      def formatted_host
        strong_memoize(:formatted_host) do
          next if @host.nil?

          uri = URI.parse(@host)
          uri.path = '/api/v3' if uri.host != 'github.com' && !uri.path.start_with?('/api/')
          uri.to_s
        end
      end

      def api_endpoint_host
        strong_memoize(:api_endpoint_host) do
          URI.parse(api_endpoint).host
        end
      end

      def valid_next_url?(next_url)
        next_url_host = URI.parse(next_url).host

        next_url_host == api_endpoint_host
      end

      def with_retry
        Retriable.retriable(on: CLIENT_CONNECTION_ERROR, on_retry: on_retry) do
          yield
        end
      end

      def on_retry
        proc do |exception, try, elapsed_time, next_interval|
          Logger.info(
            message: "GitHub connection retry triggered",
            'error.class': exception.class,
            'exception.message': exception.message,
            try_count: try,
            elapsed_time_s: elapsed_time,
            wait_to_retry_s: next_interval
          )
        end
      end
    end
  end
end

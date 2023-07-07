# frozen_string_literal: true

module Gitlab
  module GithubImport
    class ClientPool
      delegate_missing_to :best_client

      def initialize(token_pool:, per_page:, parallel:, host: nil)
        @token_pool = token_pool
        @host = host
        @per_page = per_page
        @parallel = parallel
      end

      # Returns the client with the most remaining requests, or the client with
      # the closest rate limit reset time, if all clients are rate limited.
      def best_client
        clients_with_requests_remaining = clients.select(&:requests_remaining?)

        return clients_with_requests_remaining.max_by(&:remaining_requests) if clients_with_requests_remaining.any?

        clients.min_by(&:rate_limit_resets_in)
      end

      private

      def clients
        @clients ||= @token_pool.map do |token|
          Client.new(
            token,
            host: @host,
            per_page: @per_page,
            parallel: @parallel
          )
        end
      end
    end
  end
end

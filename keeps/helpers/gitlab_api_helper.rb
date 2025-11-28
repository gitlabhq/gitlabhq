# frozen_string_literal: true

require 'gitlab-http'

module Keeps
  module Helpers
    class GitlabApiHelper
      MINIMUM_REMAINING_RATE = 25

      def initialize
        Gitlab::HTTP_V2.configure do |config|
          config.allowed_internal_uris = []
          config.log_exception_proc = ->(exception, extra_info) do
            p exception
            p extra_info
          end
          config.silent_mode_log_info_proc = ->(message, http_method) do
            p message
            p http_method
          end
          config.log_with_level_proc = ->(log_level, message_params) do
            p log_level
            p message_params
          end
        end
      end

      def query_api(url)
        get_result = {}

        begin
          print '.'
          url = get_result.fetch(:next_page_url) { url }

          puts "query_api: #{url}"
          get_result = get(url)

          results = get_result.delete(:results)

          case results
          when Array
            results.each { |result| yield(result) }
          else
            raise "Unexpected response: #{results.inspect}"
          end

          rate_limit_wait(get_result)
        end while get_result.delete(:more_pages)
      end

      def get(url)
        http_response = Gitlab::HTTP_V2.get( # rubocop:disable Gitlab/HttpV2 -- Not running inside rails application
          url,
          headers: {
            'User-Agent' => "GitLab-Housekeeper/#{self.class.name}",
            'Content-type' => 'application/json',
            'PRIVATE-TOKEN': ENV['GITLAB_QA_TEST_FAILURE_ISSUE_ACCESS_TOKEN']
          }
        )

        {
          more_pages: (http_response.headers['x-next-page'].to_s != ""),
          next_page_url: next_page_url(url, http_response),
          results: http_response.parsed_response,
          ratelimit_remaining: http_response.headers['ratelimit-remaining'],
          ratelimit_reset_at: http_response.headers['ratelimit-reset']
        }
      end

      def next_page_url(url, http_response)
        return unless http_response.headers['x-next-page'].present?

        next_page = "&page=#{http_response.headers['x-next-page']}"

        if url.include?('&page')
          url.gsub(/&page=\d+/, next_page)
        else
          url + next_page
        end
      end

      def rate_limit_wait(get_result)
        ratelimit_remaining = get_result.fetch(:ratelimit_remaining)
        ratelimit_reset_at = get_result.fetch(:ratelimit_reset_at)

        return if ratelimit_remaining.nil? || ratelimit_reset_at.nil?
        return if ratelimit_remaining.to_i >= MINIMUM_REMAINING_RATE

        ratelimit_reset_at = Time.at(ratelimit_reset_at.to_i)

        puts "Rate limit almost exceeded, sleeping for #{ratelimit_reset_at - Time.now} seconds"
        sleep(1) until Time.now >= ratelimit_reset_at
      end
    end
  end
end

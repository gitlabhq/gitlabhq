# frozen_string_literal: true

# This script revokes all active personal access tokens owned by a given USER_ID
# up to a given date (Date.today - 1 by default)
# Required environment variables: USER_ID, GITLAB_QA_ACCESS_TOKEN and GITLAB_ADDRESS
# Run `rake revoke_user_pats`

module QA
  module Tools
    class RevokeUserPersonalAccessTokens
      include Support::API

      def initialize(revoke_before: (Date.today - 1).to_s, dry_run: false)
        raise ArgumentError, "Please provide GITLAB_ADDRESS environment variable" unless ENV['GITLAB_ADDRESS']

        unless ENV['GITLAB_QA_ACCESS_TOKEN']
          raise ArgumentError, "Please provide GITLAB_QA_ACCESS_TOKEN environment variable"
        end

        raise ArgumentError, "Please provide USER_ID environment variable" unless ENV['USER_ID']

        @revoke_before = Date.parse(revoke_before)
        @dry_run = dry_run
        @api_client = Runtime::API::Client.new(ENV['GITLAB_ADDRESS'],
          personal_access_token: ENV['GITLAB_QA_ACCESS_TOKEN'])
      end

      def run
        $stdout.puts 'Running...'

        tokens_head_response = head Runtime::API::Request.new(@api_client,
          "/personal_access_tokens?user_id=#{ENV['USER_ID']}",
          per_page: "100").url

        total_token_pages = tokens_head_response.headers[:x_total_pages]
        total_tokens = tokens_head_response.headers[:x_total]

        $stdout.puts "Total tokens: #{total_tokens}. Total pages: #{total_token_pages}"

        tokens = fetch_tokens

        revoke_tokens(tokens, @api_client, @dry_run) unless tokens.empty?
        $stdout.puts "\nDone"
      end

      private

      def fetch_tokens
        fetched_tokens = []

        page_no = 1

        while page_no > 0
          tokens_response = get Runtime::API::Request.new(@api_client,
            "/personal_access_tokens?user_id=#{ENV['USER_ID']}",
            page: page_no.to_s, per_page: "100").url

          fetched_tokens
            .concat(JSON.parse(tokens_response.body)
                        .select { |token| Date.parse(token["created_at"]) < @revoke_before && token['active'] }
                        .map { |token| { id: token["id"], name: token["name"], created_at: token["created_at"] } }
                   )

          page_no = tokens_response.headers[:x_next_page].to_i
        end

        fetched_tokens
      end

      def revoke_tokens(tokens, api_client, dry_run = false)
        if dry_run
          $stdout.puts "Following #{tokens.count} tokens would be revoked:"
        else
          $stdout.puts "Revoking #{tokens.count} tokens..."
        end

        tokens.each do |token|
          if dry_run
            $stdout.puts "Token name: #{token[:name]}, id: #{token[:id]}, created at: #{token[:created_at]}"
          else
            request_url = Runtime::API::Request.new(api_client, "/personal_access_tokens/#{token[:id]}").url

            $stdout.puts "\nRevoking token with name: #{token[:name]}, " \
             "id: #{token[:id]}, created at: #{token[:created_at]}"

            delete_response = delete(request_url)
            dot_or_f = delete_response.code == 204 ? "\e[32m.\e[0m" : "\e[31mF - #{delete_response}\e[0m"
            print dot_or_f
          end
        end
      end
    end
  end
end

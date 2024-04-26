# frozen_string_literal: true

# This script revokes all active personal access tokens owned by a given USER_ID
# up to a given date (Date.today - 1 by default)
# Required environment variables: USER_ID, GITLAB_QA_ACCESS_TOKEN and GITLAB_ADDRESS
# Run `rake revoke_user_pats`
#
# @example
#   # Do a dry run of revoking access tokens for gitlab-qa-user1 up to 2024-04-20
#   GITLAB_ADDRESS=https://gitlab.com \
#   GITLAB_QA_ACCESS_TOKEN=<token for gitlab-qa-user1> \
#   USER_ID=<user id for gitlab-qa-user1> \
#   bundle exec rake "revoke_user_pats[2024-04-20, true]"

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
        @page_no = '1'
      end

      def run
        puts "Fetching QA access tokens for user (id: #{ENV['USER_ID']}) on #{ENV['GITLAB_ADDRESS']}..."

        fetch_tokens do |tokens|
          revoke_tokens(tokens) unless tokens.empty?
        end

        puts "\nDone"
      end

      private

      attr_reader :dry_run, :page_no, :api_client
      alias_method :dry_run?, :dry_run

      def fetch_tokens
        fetched_tokens = []

        while page_no.present?
          puts "Page no: #{@page_no}"

          response = get Runtime::API::Request.new(@api_client,
            "/personal_access_tokens?user_id=#{ENV['USER_ID']}",
            page: page_no.to_s, per_page: "100").url

          if response.code != 200
            puts "Failed to get tokens (response code: #{response.code}): #{response.body}"
            exit 1
          end

          tokens = JSON.parse(response.body)
            .select { |token| Date.parse(token["created_at"]) < @revoke_before }
            .map do |token|
              {
                id: token["id"],
                name: token["name"],
                created_at: token["created_at"],
                active: token['active']
              }
            end
          fetched_tokens.concat(tokens)

          # When we reach the last page, the x-next-page header is a blank string
          @page_no = response.headers[:x_next_page].to_i

          yield tokens if block_given?

          if page_no.to_i > 100
            puts "Finishing early to avoid timing out the CI job"
            break
          end
        end

        fetched_tokens
      end

      def revoke_tokens(tokens)
        if dry_run?
          puts "Following #{tokens.count} tokens would be revoked:"
        else
          puts "Revoking #{tokens.count} tokens..."
        end

        tokens.each do |token|
          if dry_run?
            puts "Token name: #{token[:name]}, id: #{token[:id]}, created at: #{token[:created_at]}"
          else
            request_url = Runtime::API::Request.new(api_client, "/personal_access_tokens/#{token[:id]}").url

            print "Revoking token with name: #{token[:name]}, " \
             "id: #{token[:id]}, created at: #{token[:created_at]} "

            delete_response = delete(request_url)
            dot_or_f = delete_response.code == 204 ? "\e[32m.\e[0m" : "\e[31mF - #{delete_response}\e[0m"
            print "#{dot_or_f}\n"
          end
        end
      end
    end
  end
end

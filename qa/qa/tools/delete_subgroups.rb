# frozen_string_literal: true

require_relative '../../qa'

# This script deletes all subgroups of a group specified by ENV['GROUP_NAME_OR_PATH']
# Required environment variables: GITLAB_QA_ACCESS_TOKEN and GITLAB_ADDRESS
# Optional environment variable: GROUP_NAME_OR_PATH (defaults to 'gitlab-qa-sandbox-group')
# Run `rake delete_subgroups`

module QA
  module Tools
    class DeleteSubgroups
      include Support::Api

      def initialize
        raise ArgumentError, "Please provide GITLAB_ADDRESS" unless ENV['GITLAB_ADDRESS']
        raise ArgumentError, "Please provide GITLAB_QA_ACCESS_TOKEN" unless ENV['GITLAB_QA_ACCESS_TOKEN']

        @api_client = Runtime::API::Client.new(ENV['GITLAB_ADDRESS'], personal_access_token: ENV['GITLAB_QA_ACCESS_TOKEN'])
      end

      def run
        STDOUT.puts 'Running...'

        # Fetch group's id
        group_id = fetch_group_id

        sub_groups_head_response = head Runtime::API::Request.new(@api_client, "/groups/#{group_id}/subgroups", per_page: "100").url
        total_sub_groups = sub_groups_head_response.headers[:x_total]
        total_sub_group_pages = sub_groups_head_response.headers[:x_total_pages]

        STDOUT.puts "total_sub_groups: #{total_sub_groups}"
        STDOUT.puts "total_sub_group_pages: #{total_sub_group_pages}"

        total_sub_group_pages.to_i.times do |page_no|
          # Fetch all subgroups for the top level group
          sub_groups_response = get Runtime::API::Request.new(@api_client, "/groups/#{group_id}/subgroups", per_page: "100").url

          sub_group_ids = JSON.parse(sub_groups_response.body).map { |subgroup| subgroup["id"] }

          if sub_group_ids.any?
            STDOUT.puts "\n==== Current Page: #{page_no + 1} ====\n"

            delete_subgroups(sub_group_ids)
          end
        end
        STDOUT.puts "\nDone"
      end

      private

      def delete_subgroups(sub_group_ids)
        sub_group_ids.each do |subgroup_id|
          delete_response = delete Runtime::API::Request.new(@api_client, "/groups/#{subgroup_id}").url
          dot_or_f = delete_response.code == 202 ? "\e[32m.\e[0m" : "\e[31mF\e[0m"
          print dot_or_f
        end
      end

      def fetch_group_id
        group_search_response = get Runtime::API::Request.new(@api_client, "/groups", search: ENV['GROUP_NAME_OR_PATH'] || 'gitlab-qa-sandbox-group').url
        JSON.parse(group_search_response.body).first["id"]
      end
    end
  end
end

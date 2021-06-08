# frozen_string_literal: true

require_relative '../../qa'

# This script deletes all subgroups of a group specified by ENV['TOP_LEVEL_GROUP_NAME']
# Required environment variables: GITLAB_QA_ACCESS_TOKEN and GITLAB_ADDRESS
# Optional environment variable: TOP_LEVEL_GROUP_NAME (defaults to 'gitlab-qa-sandbox-group')
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
        $stdout.puts 'Running...'

        # Fetch group's id
        group_id = fetch_group_id

        sub_groups_head_response = head Runtime::API::Request.new(@api_client, "/groups/#{group_id}/subgroups", per_page: "100").url
        total_sub_group_pages = sub_groups_head_response.headers[:x_total_pages]

        sub_group_ids = fetch_subgroup_ids(group_id, total_sub_group_pages)
        $stdout.puts "Number of Sub Groups not already marked for deletion: #{sub_group_ids.length}"

        delete_subgroups(sub_group_ids) unless sub_group_ids.empty?
        $stdout.puts "\nDone"
      end

      private

      def delete_subgroups(sub_group_ids)
        $stdout.puts "Deleting #{sub_group_ids.length} subgroups..."
        sub_group_ids.each do |subgroup_id|
          delete_response = delete Runtime::API::Request.new(@api_client, "/groups/#{subgroup_id}").url
          dot_or_f = delete_response.code == 202 ? "\e[32m.\e[0m" : "\e[31mF\e[0m"
          print dot_or_f
        end
      end

      def fetch_group_id
        group_name = ENV['TOP_LEVEL_GROUP_NAME'] || 'gitlab-qa-sandbox-group'
        group_search_response = get Runtime::API::Request.new(@api_client, "/groups/#{group_name}" ).url
        JSON.parse(group_search_response.body)["id"]
      end

      def fetch_subgroup_ids(group_id, group_pages)
        sub_groups_ids = []

        group_pages.to_i.times do |page_no|
          sub_groups_response = get Runtime::API::Request.new(@api_client, "/groups/#{group_id}/subgroups", page: (page_no + 1).to_s, per_page: "100").url
          sub_groups_ids.concat(JSON.parse(sub_groups_response.body).reject { |subgroup| !subgroup["marked_for_deletion_on"].nil? }.map { |subgroup| subgroup["id"] })
        end

        sub_groups_ids.uniq
      end
    end
  end
end

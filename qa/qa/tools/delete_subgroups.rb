# frozen_string_literal: true

# This script deletes all subgroups of a group specified by ENV['TOP_LEVEL_GROUP_NAME']
#
# Required environment variables: GITLAB_QA_ACCESS_TOKEN and GITLAB_ADDRESS
# Optional environment variable: TOP_LEVEL_GROUP_NAME (defaults to 'gitlab-qa-sandbox-group-<current weekday #>')

# Optional environment variable: CLEANUP_ALL_QA_SANDBOX_GROUPS (defaults to false)
# Set CLEANUP_ALL_QA_SANDBOX_GROUPS to true if you would like to delete all subgroups under all
# 'gitlab-qa-sandbox-group-*' groups. Otherwise, this will fall back to TOP_LEVEL_GROUP_NAME.

# Optional environment variable: PERMANENTLY_DELETE (defaults to false)
# Set PERMANENTLY_DELETE to true if you would like to permanently delete subgroups on an environment with
# deletion protection enabled. Otherwise, subgroups will remain available during the retention period specified
# in admin settings. On environments with deletion protection disabled, subgroups will always be permanently deleted.
#
# Run `rake delete_subgroups`

module QA
  module Tools
    class DeleteSubgroups < DeleteResourceBase
      def run
        if ENV['CLEANUP_ALL_QA_SANDBOX_GROUPS']
          SANDBOX_GROUPS.each do |name|
            group_id = fetch_group_id(@api_client, name)
            delete_subgroups(group_id)
          end

        else
          group_id = fetch_group_id(@api_client)
          delete_subgroups(group_id)
        end
      end

      private

      def delete_subgroups(group_id)
        return unless group_id

        subgroups = fetch_subgroups(group_id)
        return logger.info('No subgroups available') if subgroups.empty?

        subgroups_marked_for_deletion = mark_for_deletion(subgroups)

        if ENV['PERMANENTLY_DELETE'] && !subgroups_marked_for_deletion.empty?
          delete_permanently(subgroups_marked_for_deletion)
        end

        print_failed_deletion_attempts

        logger.info('Done')
      end

      def fetch_subgroups(group_id)
        logger.info("Fetching subgroups...")

        api_path = "/groups/#{group_id}/subgroups"
        page_no = '1'
        subgroups = []

        while page_no.present?
          subgroups_response = get Runtime::API::Request.new(@api_client, api_path, page: page_no, per_page: '100').url

          if subgroups_response.code == HTTP_STATUS_OK
            # Do not delete subgroups that are less than 4 days old (for debugging purposes)
            subgroups.concat(parse_body(subgroups_response).select { |subgroup| Date.parse(subgroup[:created_at]) < @delete_before })
          else
            logger.error("Request for subgroups returned (#{subgroups_response.code}): `#{subgroups_response}` ")
          end

          page_no = subgroups_response.headers[:x_next_page].to_s
        end

        subgroups
      end

      def subgroup_request(subgroup, **options)
        Runtime::API::Request.new(@api_client, "/groups/#{subgroup[:id]}", **options).url
      end

      def process_response_and_subgroup(response, subgroup, opts = {})
        if response.code == 202
          logger.info("Success\n")
          opts[:save_successes_to] << subgroup if opts[:save_successes_to]
        else
          logger.error("Failed - #{response}\n")
          @failed_deletion_attempts << { path: subgroup[:full_path], response: response }
        end
      end

      def mark_for_deletion(subgroups)
        subgroups_marked_for_deletion = []

        logger.info("Marking #{subgroups.length} subgroups for deletion...\n")

        subgroups.each do |subgroup|
          path = subgroup[:full_path]

          if subgroup[:marked_for_deletion_on].nil?
            logger.info("Marking subgroup #{path} for deletion...")
            response = delete(subgroup_request(subgroup))

            process_response_and_subgroup(response, subgroup, save_successes_to: subgroups_marked_for_deletion)
          else
            logger.info("Subgroup #{path} already marked for deletion\n")
            subgroups_marked_for_deletion << subgroup
          end
        end

        subgroups_marked_for_deletion
      end

      def subgroup_exists?(subgroup)
        response = get(subgroup_request(subgroup))

        if response.code == 404
          logger.info("Subgroup #{subgroup[:full_path]} is no longer available\n")
          false
        else
          true
        end
      end

      def delete_permanently(subgroups)
        logger.info("Permanently deleting #{subgroups.length} subgroups...\n")

        subgroups.each do |subgroup|
          path = subgroup[:full_path]

          next unless subgroup_exists?(subgroup)

          logger.info("Permanently deleting subgroup #{path}...")
          delete_subgroup_response = delete(subgroup_request(subgroup, permanently_remove: true, full_path: path))

          process_response_and_subgroup(delete_subgroup_response, subgroup)
        end
      end

      def print_failed_deletion_attempts
        if @failed_deletion_attempts.empty?
          logger.info('No failed deletion attempts to report!')
        else
          logger.info("There were #{@failed_deletion_attempts.length} failed deletion attempts:\n")

          @failed_deletion_attempts.each do |attempt|
            logger.info("Subgroup: #{attempt[:path]}")
            logger.error("Response: #{attempt[:response]}\n")
          end
        end
      end
    end
  end
end

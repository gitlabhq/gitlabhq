# frozen_string_literal: true

module QA
  module Tools
    class DeleteResourceBase
      include Ci::Helpers
      include Lib::Group
      include Lib::Project
      include Support::API
      include Support::Repeater
      include Support::Waiter

      ITEMS_PER_PAGE = '100'
      PAGE_CUTOFF = '10'
      SANDBOX_GROUPS = %w[gitlab-qa-sandbox-group
        gitlab-qa-sandbox-group-0
        gitlab-qa-sandbox-group-1
        gitlab-qa-sandbox-group-2
        gitlab-qa-sandbox-group-3
        gitlab-qa-sandbox-group-4
        gitlab-qa-sandbox-group-5
        gitlab-qa-sandbox-group-6
        gitlab-qa-sandbox-group-7].freeze

      def initialize(dry_run: false)
        %w[GITLAB_ADDRESS GITLAB_QA_ACCESS_TOKEN].each do |var|
          raise ArgumentError, "Please provide #{var} environment variable" unless ENV[var]
        end

        @api_client = Runtime::API::Client.new(ENV['GITLAB_ADDRESS'],
          personal_access_token: ENV['GITLAB_QA_ACCESS_TOKEN'])
        @delete_before = Date.parse(ENV['DELETE_BEFORE'] || (Date.today - 1).to_s)
        @dry_run = dry_run
        @permanently_delete = !!(ENV['PERMANENTLY_DELETE'].to_s =~ /true|1|y/i)
        @type = nil
      end

      # Permanently deletes a given resource
      #
      # @param [Hash] resource
      # @return [Array<String, Hash>] results
      def delete_permanently(resource)
        # We need to get the path_with_namespace of the project again since marking it for deletion changes the name
        resource = get_resource(resource) if @type.include?('project')
        return unless resource

        path = resource_path(resource)
        response = delete(resource_request(resource, permanently_remove: true, full_path: path))
        wait_for_resource_deletion(resource, true) if success?(response&.code)

        if permanently_deleted?(resource)
          log_permanent_deletion(resource)
        else
          log_failure(resource, response)
        end
      end

      # Deletes a list of resources
      #
      # @param [Array<Hash>] resources
      # @param [Boolean] wait until the end of the script to verify deletions. used for deletions that take a long time
      # @param [Hash] API call options
      # @return [Array<String, Hash>] results
      def delete_resources(resources, delayed_verification = false, **options)
        logger.info("Deleting #{resources.length} #{@type}s...\n")

        unverified_deletions = []
        results = []

        resources.each do |resource|
          path = resource_path(resource)
          logger.info("Deleting #{@type} #{path}...")

          result = delete_resource(resource, delayed_verification, **options)

          if result.is_a?(Array)
            results.append(result)
          else
            unverified_deletions << result
          end
        end

        results.concat(verify_deletions(unverified_deletions)) unless unverified_deletions.empty?

        results
      end

      # Deletes a given resource
      #
      # @param [<Hash>] resource
      # @param [Boolean] wait until the end of the script to verify deletion
      # @param [Hash] API call options
      # @return [Array<String, Hash>] results
      def delete_resource(resource, delayed_verification = false, **options)
        # If delayed deletion is not enabled, resource will be permanently deleted
        response = delete(resource_request(resource, **options))

        if success?(response&.code) || response.include?("already marked for deletion")
          return resource if delayed_verification

          wait_for_resource_deletion(resource)

          return log_permanent_deletion(resource) if permanently_deleted?(resource)

          return log_failure(resource, response) unless mark_for_deletion_possible?(resource)

          @permanently_delete ? delete_permanently(resource) : log_marked_for_deletion(resource)
        elsif response&.code == HTTP_STATUS_NOT_FOUND
          log_permanent_deletion(resource)
        else
          log_failure(resource, response)
        end
      end

      def fetch_qa_user_id(qa_username)
        user_response = get Runtime::API::Request.new(@api_client, "/users", username: qa_username).url

        unless user_response.code == HTTP_STATUS_OK
          logger.error("Request for #{qa_username} returned (#{user_response.code}): `#{user_response}` ")
          exit 1 if user_response.code == HTTP_STATUS_UNAUTHORIZED
          return
        end

        parsed_response = parse_body(user_response)

        if parsed_response.empty?
          logger.error("User #{qa_username} not found")
          return
        end

        parsed_response.first[:id]
      rescue StandardError => e
        logger.error("Failed to fetch user ID for #{qa_username}: #{e.message}")
      end

      # Fetches resources by api path that were created before the @delete_before date
      #
      # @param api_path [String] api path to fetch resources from
      # @return [Array<Hash>] list of parsed resource hashes
      def fetch_resources(api_path)
        logger.info("Fetching #{@type}s created before #{@delete_before} on #{ENV['GITLAB_ADDRESS']}...")

        page_no = '1'
        resources = []

        while page_no.present?
          response = get Runtime::API::Request.new(
            @api_client,
            api_path,
            page: page_no,
            per_page: ITEMS_PER_PAGE
          ).url

          if response.code == HTTP_STATUS_OK
            resources.concat(parse_body(response).select { |r| Date.parse(r[:created_at]) < @delete_before })
          else
            logger.error("Request for #{@type} returned (#{response.code}): `#{response}` ")
            exit 1 if response.code == HTTP_STATUS_UNAUTHORIZED
          end

          page_no = response.headers[:x_next_page].to_s

          next unless page_no.to_i == (PAGE_CUTOFF.to_i + 1)

          logger.warn("Stopping at page #{PAGE_CUTOFF} to avoid timeout, #{@type}s per page: #{ITEMS_PER_PAGE},\n")
          break
        end

        resources
      end

      # Fetches the given resource again and parses its response
      #
      # @param [Hash] resource
      # @return [Hash] resource
      def get_resource(resource)
        response = get(resource_request(resource))

        if success?(response&.code)
          parse_body(response)
        else
          logger.warn("Get #{resource_path(resource)}, returned #{response.code}")
          nil
        end
      end

      # Print results of dry run
      #
      # @param [Array<Hash>] list of resource hashes
      # @return [void]
      def log_dry_run_output(resources)
        return logger.info("No #{@type}s would be deleted") if resources.empty?

        logger.info("The following #{resources.length} #{@type}s would be deleted:")

        resources.each do |resource|
          created_at = resource[:created_at]
          path = resource_path(resource)
          logger.info("#{path} - created at: #{created_at}")
        end
      end

      # Print failure message for a given resource
      #
      # @param [<Hash>] resource
      # @param [<Hash>] response
      # @return [Array<String, Hash>] results
      def log_failure(resource, response)
        path = resource_path(resource)
        logger.error("\e[31mFAILED\e[0m to delete #{@type} #{path} with #{response.code}.\n")
        ["failed_deletions", { path: path, response: response }]
      end

      # Print marked for deletion message for a given resource
      #
      # @param [<Hash>] resource
      # @return [Array<String, Hash>] results
      def log_marked_for_deletion(resource)
        path = resource_path(resource)
        logger.info("\e[32mSUCCESS\e[0m: Marked #{@type} #{path} for deletion\n")
        ["marked_deletions", resource]
      end

      # Print permanent deletion message for a given resource
      #
      # @param [<Hash>] resource
      # @return [Array<String, Hash>] results
      def log_permanent_deletion(resource)
        path = resource_path(resource)
        logger.info("\e[32mSUCCESS\e[0m: Permanently deleted #{@type} #{path}\n")
        ["permanent_deletions", resource]
      end

      # Print results of entire script run
      #
      # @param [Array<String, Hash>] results
      # @return [void]
      def log_results(results)
        return logger.info("Dry run complete") if @dry_run

        return logger.info("No results to report") if results.blank?

        processed_results = results.group_by(&:shift).transform_values(&:flatten)

        marked_deletions = processed_results["marked_deletions"]
        permanent_deletions = processed_results["permanent_deletions"]
        failed_deletions = processed_results["failed_deletions"]

        logger.info("Marked #{marked_deletions.length} #{@type}(s) for deletion") unless marked_deletions.blank?
        logger.info("Deleted #{permanent_deletions.length} #{@type}(s)") unless permanent_deletions.blank?

        print_failed_deletion_attempts(failed_deletions)

        logger.info('Done')

        exit 1 unless failed_deletions.blank?
      end

      # Check if a resource can be marked for deletion
      #
      # @param resource [Hash] Resource to check
      # @return [Boolean]
      def mark_for_deletion_possible?(resource)
        resource.key?(:marked_for_deletion_on)
      end

      # Check if resource is marked for deletion
      #
      # @param resource [Hash] Resource to check
      # @param fetch_again [Boolean] Whether to fetch the resource again before checking
      # @return [Boolean]
      def marked_for_deletion?(resource, fetch_again: false)
        if fetch_again
          resource = get_resource(resource)
          return false unless resource
        end

        resource[:marked_for_deletion_on]
      end

      # Check if resource is permanently deleted
      #
      # @param resource [Hash] Resource to check
      # @return [Boolean]
      def permanently_deleted?(resource)
        response = get(resource_request(resource))
        response.code == HTTP_STATUS_NOT_FOUND
      end

      # Prints failed deletion attempts
      #
      # @param failed_deletions [Array<Hash{path=>String, response=>Hash}>] List of hashes of failed deletion attempts
      # @return [void]
      def print_failed_deletion_attempts(failed_deletions)
        return logger.info('No failed deletion attempts to report!') if failed_deletions.blank?

        logger.info("\e[31mThere were #{failed_deletions.length} failed deletion attempts:\e[0m\n")

        failed_deletions.each do |attempt|
          logger.info("Resource: #{attempt[:path]}")
          logger.error("Response: #{attempt[:response]}\n")
        end
      end

      # Resource path of a given resource
      #
      # @param resource [Hash] Resource
      # @return [String] Resource path
      def resource_path(resource)
        resource[:full_path] || resource[:path_with_namespace] || resource[:web_url]
      end

      # Create a new api client for the specified token - used for deleting test user personal resources
      #
      # @param token [String] Personal access token
      # @return [Runtime::API::Client] API client
      def user_api_client(token)
        Runtime::API::Client.new(ENV['GITLAB_ADDRESS'],
          personal_access_token: token)
      end

      def verify_deletions(unverified_deletions)
        logger.info('Verifying deletions...')

        unverified_deletions.filter_map do |resource|
          wait_for_resource_deletion(resource, permanent: true)
          response = get(resource_request(resource))

          if response&.code == HTTP_STATUS_NOT_FOUND
            log_permanent_deletion(resource)
          else
            log_failure(resource, response)
          end
        end
      end

      # Wait for resource to be deleted (resource cannot be found or resource has been marked for deletion)
      #
      # @param resource [Hash] Resource to wait for deletion for
      # @return [Boolean] Whether the resource was deleted
      def wait_for_resource_deletion(resource, permanent = false)
        wait_until(max_duration: 160, sleep_interval: 1, raise_on_failure: false) do
          response = get(resource_request(resource))
          deleted = response&.code == HTTP_STATUS_NOT_FOUND

          if permanent
            deleted
          else
            deleted || (success?(response&.code) && marked_for_deletion?(parse_body(response)))
          end
        end
      end
    end
  end
end

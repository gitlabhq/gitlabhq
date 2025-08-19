# frozen_string_literal: true

module QA
  module Tools
    module SharedResourceDeletion
      include Ci::Helpers
      include Lib::Group
      include Lib::Project
      include Support::API
      include Support::Repeater
      include Support::Waiter

      # Permanently deletes a given resource
      #
      # @param [Hash] resource
      # @param [Boolean] delayed_verification Wait until the end of the script to verify deletion
      # @param [Boolean] skip_verification Skip verification of deletion for time constraint purposes
      # @return [Array<String, Hash>] results
      def delete_permanently(resource, delayed_verification = false, skip_verification = false)
        # Get the path of the project or group again since marking it for deletion changes the name
        updated_path = get_resource(resource)
        return unless updated_path

        resource[:full_path] = updated_path[:full_path] if resource[:type].include?('group')
        resource[:path_with_namespace] = updated_path[:path_with_namespace] if resource[:type].include?('project')

        path = resource_path(resource)
        response = delete(resource_request(resource, permanently_remove: true, full_path: path))

        return log_failure(resource, response) unless success?(response&.code)

        return resource if delayed_verification

        return log_permanent_deletion(resource) if skip_verification

        wait_for_resource_deletion(resource, true)

        permanently_deleted?(resource) ? log_permanent_deletion(resource) : log_failure(resource, response)
      end

      # Deletes a given resource
      #
      # @param [<Hash>] resource
      # @param [Boolean] delayed_verification Wait until the end of the script to verify deletion
      # @param [Boolean] permanent Permanently delete resources instead of marking for deletion
      # @param [Boolean] skip_verification Skip verification of deletion for time constraint purposes
      # @param [Hash] API call options
      # @return [Array<String, Hash>] results
      def delete_resource(
        resource, delayed_verification = false, permanent = false, skip_verification = false,
        **options)
        max_retries = 6
        retry_count = 0

        while retry_count <= max_retries
          response = delete(resource_request(resource, **options))

          case
          when deletion_successful?(response)
            return handle_successful_deletion(resource, response, delayed_verification, permanent, skip_verification)
          when response&.code == HTTP_STATUS_NOT_FOUND
            return log_permanent_deletion(resource)
          when should_remove_security_policy?(response, retry_count, max_retries)
            find_and_unassign_security_policy_project(resource)
            retry_count += 1
          when resource[:type] == 'project' && should_remove_registry_tags?(response, retry_count, max_retries)
            remove_registry_tags(resource)
            retry_count += 1
          else
            return log_failure(resource, response)
          end
        end

        log_failure(resource, response)
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
          path = resource.is_a?(String) ? resource : resource_path(resource)
          logger.warn("Get #{path}, returned #{response.code}")
          nil
        end
      end

      # Checks if resource type is a group or project
      #
      # @param [Hash] resource
      # @return [Boolean]
      def group_or_project?(resource)
        %w[group project].include?(resource[:type])
      end

      # Print results of dry run
      #
      # @param [Array<Hash>] resources List of resource hashes
      # @return [void]
      def log_dry_run_output(resources)
        return logger.info("No resources would be deleted") if resources.empty?

        logger.info("The following #{resources.length} resources would be deleted:")

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
        logger.error("\e[31mFAILED\e[0m to delete #{resource[:type]} #{path} with #{response.code}.\n")
        ["failed_deletions", { path: path, response: response }]
      end

      # Print marked for deletion message for a given resource
      #
      # @param [<Hash>] resource
      # @return [Array<String, Hash>] results
      def log_marked_for_deletion(resource)
        path = resource_path(resource)
        logger.info("\e[32mSUCCESS\e[0m: Marked #{resource[:type]} #{path} for deletion\n")
        ["marked_deletions", resource]
      end

      # Print permanent deletion message for a given resource
      #
      # @param [<Hash>] resource
      # @return [Array<String, Hash>] results
      def log_permanent_deletion(resource)
        path = resource_path(resource)
        logger.info("\e[32mSUCCESS\e[0m: Permanently deleted #{resource[:type]} #{path}\n")
        ["permanent_deletions", resource]
      end

      # Print results of entire script run
      #
      # @param [Array<String, Hash>] results
      # @param [Boolean] dry_run Defaults to false
      # @return [void]
      def log_results(results, dry_run = false)
        return logger.info("Dry run complete") if dry_run

        return logger.info("No results to report") if results.blank?

        processed_results = results.group_by(&:shift).transform_values(&:flatten)

        marked_deletions = processed_results["marked_deletions"]
        permanent_deletions = processed_results["permanent_deletions"]
        failed_deletions = processed_results["failed_deletions"]

        logger.info("Marked #{marked_deletions.length} resource(s) for deletion") unless marked_deletions.blank?
        logger.info("Deleted #{permanent_deletions.length} resource(s)") unless permanent_deletions.blank?

        print_failed_deletion_attempts(failed_deletions)

        logger.info('Done')

        exit 1 unless failed_deletions.blank?
      end

      # Check if a resource can be marked for deletion
      #
      # @param [Hash] resource Resource to check
      # @return [Boolean]
      def mark_for_deletion_possible?(resource)
        return false unless group_or_project?(resource) || resource[:type] == 'sandbox'

        resource.key?(:marked_for_deletion_on)
      end

      # Check if resource is marked for deletion
      #
      # @param [Hash]resource Resource to check
      # @param[Boolean] fetch_again Whether to fetch the resource again before checking. Default: false
      # @return [Boolean]
      def self_deletion_scheduled?(resource, fetch_again: false)
        if fetch_again
          resource = get_resource(resource)
          return false unless resource
        end

        resource[:marked_for_deletion_on]
      end

      # Check if resource is permanently deleted
      #
      # @param [Hash] resource Resource to check
      # @return [Boolean]
      def permanently_deleted?(resource)
        response = get(resource_request(resource))
        response.code == HTTP_STATUS_NOT_FOUND
      end

      # Prints failed deletion attempts
      #
      # @param [Array<Hash{path=>String, response=>Hash}>] failed_deletions List of hashes of failed deletion attempts
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
      # @param [Hash] resource Resource
      # @return [String] Resource path
      def resource_path(resource)
        resource[:full_path] || resource[:path_with_namespace] || resource[:web_url]
      end

      # Create a new api client for the specified token - used for deleting test user personal resources
      #
      # @param [String] token Personal access token
      # @return [Runtime::API::Client] API client
      def user_api_client(token)
        Runtime::API::Client.new(ENV['GITLAB_ADDRESS'],
          personal_access_token: token)
      end

      # Verifies deletions of given resources by attempting to find them. If the resource is found,
      # logs a failure. Used with delayed_verification.
      #
      # @param [Array<Hash>] unverified_deletions List of resources that were not verified
      # @param [Boolean] permanent If resource is permanently deleted or only marked for deletion
      # @return [void]
      def verify_deletions(unverified_deletions, permanent)
        logger.info('Verifying deletions...')

        unverified_deletions.filter_map do |resource|
          wait_for_resource_deletion(resource, permanent: permanent)
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
      # @param [Hash] resource Resource to wait for deletion for
      # @return [Boolean] Whether the resource was deleted
      def wait_for_resource_deletion(resource, permanent = false)
        wait_until(max_duration: 160, sleep_interval: 2, raise_on_failure: false) do
          response = get(resource_request(resource))
          deleted = response&.code == HTTP_STATUS_NOT_FOUND

          if permanent && resource[:type] != 'sandbox'
            deleted
          else
            deleted || (success?(response&.code) && self_deletion_scheduled?(parse_body(response)))
          end
        end
      end

      # Finds and unassigns a security policy project from a resource
      # Note: full_path is used for REST API resources and fullPath is used for GraphQL resources
      # We can only unassign a security policy project through GraphQL and not the REST API.
      #
      # @param [Hash] resource Resource to remove security policy project from
      # @return [void]
      def find_and_unassign_security_policy_project(resource)
        if has_security_policy_project?(resource)
          unassign_security_policy_project(resource[:full_path])
        elsif projects_with_security_policy_projects(resource).present?
          projects_with_security_policy_projects(resource).each do |project|
            unassign_security_policy_project(project[:fullPath])
          end
        elsif subgroups_with_security_policy_projects(resource).present?
          subgroups_with_security_policy_projects(resource).each do |subgroup|
            unassign_security_policy_project(subgroup[:fullPath])
          end
        end
      end

      private

      # Unassigns security policy project from resource
      #
      # @param [String] path Full path of the resource
      # @return [response]
      def unassign_security_policy_project(path)
        logger.info("Unassigning security policy project for #{path}")

        mutation = <<~GQL
          mutation {
            securityPolicyProjectUnassign(input: { fullPath: "#{path}" }) {
              errors
            }
          }
        GQL

        graphql_request(mutation)
      end

      # Posts GraphQL request
      #
      # @param [query] query GraphQL query
      # @return [response]
      def graphql_request(query)
        response = post(Runtime::API::Request.new(api_client, '/graphql').url, { query: query })
        parse_body(response)
      end

      # Checks if response was successful
      #
      # @param [Hash] response
      # @return [Boolean]
      def deletion_successful?(response)
        success?(response&.code) || response.include?("already marked for deletion")
      end

      # Handles successful deletion
      #
      # @param [Hash] resource
      # @param [Hash] response
      # @param [Boolean] delayed_verification Wait until the end of the script to verify deletion
      # @param [Boolean] permanent
      # @param [Boolean] skip_verification
      # @return [Array<String, Hash>] results
      def handle_successful_deletion(resource, response, delayed_verification, permanent, skip_verification)
        return resource if delayed_verification && !group_or_project?(resource)

        if skip_verification
          # If skip_verification is true and it's a group or project, delete permanently if permanent set
          if group_or_project?(resource) && permanent
            return delete_permanently(resource, delayed_verification,
              skip_verification)
          end

          return log_marked_for_deletion(resource)

        end

        wait_for_resource_deletion(resource)

        return log_permanent_deletion(resource) if permanently_deleted?(resource)
        return log_failure(resource, response) unless mark_for_deletion_possible?(resource)

        if permanent && resource[:type] != 'sandbox'
          delete_permanently(resource, delayed_verification)
        else
          log_marked_for_deletion(resource)
        end
      end

      # Checks if response indicates that the request failed because of a security policy project association
      #
      # @param [Hash] response
      # @param [Integer] retry_count
      # @param [Integer] max_retries
      # @return [Boolean]
      def should_remove_security_policy?(response, retry_count, max_retries)
        response&.code == HTTP_STATUS_BAD_REQUEST &&
          response&.include?("security policy project") &&
          retry_count < max_retries
      end

      # Checks if response indicates that the request failed because of container registry tags
      #
      # @param [Hash] response
      # @param [Integer] retry_count
      # @param [Integer] max_retries
      # @return [Boolean]
      def should_remove_registry_tags?(response, retry_count, max_retries)
        response&.code == HTTP_STATUS_BAD_REQUEST &&
          response&.include?("Cannot rename project, the container registry path rename validation failed") &&
          retry_count < max_retries
      end

      # Removes all registry tags and repositories for a given project resource
      #
      # @param [Hash] resource Project resource containing project ID
      # @return [Boolean] Whether the operation was successful
      def remove_registry_tags(resource)
        project_id = extract_project_id(resource)
        return unless project_id

        logger.info("Removing registry tags for project #{project_id}...")

        repositories = fetch_registry_repositories(project_id)
        return if repositories.empty?

        repositories.each do |repository|
          remove_repository_tags(project_id, repository)
          delete_registry_repository(project_id, repository[:id])
        end

        logger.info("Successfully removed all registry tags for project #{project_id}")
      rescue StandardError => e
        logger.error("Failed to remove registry tags for project #{project_id}: #{e.message}")
      end
    end
  end
end

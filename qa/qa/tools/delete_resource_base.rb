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
      include SharedResourceDeletion

      ITEMS_PER_PAGE = '100'
      PAGE_CUTOFF = '10'
      SANDBOX_GROUPS = %w[gitlab-e2e-sandbox-group-1
        gitlab-e2e-sandbox-group-2
        gitlab-e2e-sandbox-group-3
        gitlab-e2e-sandbox-group-4
        gitlab-e2e-sandbox-group-5
        gitlab-e2e-sandbox-group-6
        gitlab-e2e-sandbox-group-7
        gitlab-e2e-sandbox-group-8].freeze
      USER_TOKENS = %w[GITLAB_QA_ADMIN_ACCESS_TOKEN
        GITLAB_QA_ACCESS_TOKEN
        GITLAB_QA_USER1_ACCESS_TOKEN
        GITLAB_QA_USER2_ACCESS_TOKEN].freeze

      def initialize(dry_run: false)
        raise ArgumentError, "Please provide GITLAB_ADDRESS environment variable" unless ENV['GITLAB_ADDRESS']

        @delete_before = Time.parse(ENV['DELETE_BEFORE'] || (Time.now - (24 * 3600)).to_s).utc.iso8601(3)
        @dry_run = dry_run
        @permanently_delete = Gitlab::Utils.to_boolean(ENV['PERMANENTLY_DELETE'], default: false)
        @skip_verification = Gitlab::Utils.to_boolean(ENV['SKIP_VERIFICATION'], default: false)
        @type = nil
      end

      def api_client
        @api_client ||= Runtime::API::Client.new(
          ENV['GITLAB_ADDRESS'],
          personal_access_token: personal_access_token
        )
      end

      # Deletes a list of resources
      #
      # @param [Array<Hash>] resources List of resources to delete
      # @param [Boolean] delayed_verifications Wait until the end of the script to verify deletions
      # @param [Boolean] permanent Permanently delete resources instead of marking for deletion
      # @param [Boolean] skip_verification Skip verification of deletion for time constraint purposes
      # @param [Hash] API call options
      # @return [Array<String, Hash>] results
      def delete_resources(
        resources, delayed_verification = false, permanent = @permanently_delete,
        skip_verification = @skip_verification, **options
      )
        logger.info("Deleting #{resources.length} #{@type}s...\n")

        unverified_deletions = []
        results = []

        resources.each do |resource|
          path = resource_path(resource)
          resource[:type] = @type

          logger.info("Deleting #{@type} #{path}...")

          result = delete_resource(resource, delayed_verification, permanent, skip_verification, **options)

          if result.is_a?(Array)
            results.append(result)
          else
            unverified_deletions << result
          end
        end

        results.concat(verify_deletions(unverified_deletions, permanent)) unless unverified_deletions.empty?

        results
      end

      # Fetches the user ID of the given username
      #
      # @param [String] qa_username
      # @return [Integer]
      def fetch_qa_user_id(qa_username)
        user_response = get Runtime::API::Request.new(api_client, "/users", username: qa_username).url

        unless user_response.code == HTTP_STATUS_OK
          logger.error("Request for #{qa_username} returned (#{user_response.code}): `#{user_response}` ")
          exit 1 if fatal_response?(user_response.code)
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
      # @param [String] api_path Api path to fetch resources from
      # @return [Array<Hash>] list of parsed resource hashes
      def fetch_resources(api_path, client = api_client)
        logger.info("Fetching #{@type}s created before #{@delete_before} on #{ENV['GITLAB_ADDRESS']}...")

        page_no = '1'
        resources = []

        while page_no.present?
          response = get Runtime::API::Request.new(
            client,
            api_path,
            page: page_no,
            per_page: ITEMS_PER_PAGE
          ).url

          if response.code == HTTP_STATUS_OK
            resources.concat(parse_body(response).select { |r| Time.parse(r[:created_at]) < @delete_before })
          else
            logger.error("Request for #{@type} returned (#{response.code}): `#{response}` ")
            exit 1 if fatal_response?(response.code)
          end

          page_no = response.headers[:x_next_page].to_s

          next unless page_no.to_i == (PAGE_CUTOFF.to_i + 1)

          logger.warn("Stopping at page #{PAGE_CUTOFF} to avoid timeout, #{@type}s per page: #{ITEMS_PER_PAGE},\n")
          break
        end

        resources
      end

      # Fetches the user who owns the token with the given token name by using the given user_api_client
      #
      # @param [String] token_name Token name, not the token itself
      # @param [Runtime::API::Client] client, api client for the token
      # @return [Hash] User
      def fetch_token_user(token_name, client = api_client)
        logger.info("Fetching #{token_name} user ...")

        user_response = get Runtime::API::Request.new(client, "/user").url

        unless user_response.code == HTTP_STATUS_OK
          logger.error("Request for user returned (#{user_response.code}): `#{user_response}` ")
          exit 1 if [HTTP_STATUS_UNAUTHORIZED, HTTP_STATUS_BAD_REQUEST].include?(user_response.code)
        end

        parsed_response = parse_body(user_response)

        if parsed_response.empty?
          logger.error("User not found")
          return {}
        end

        parsed_response
      rescue StandardError => e
        logger.error("Failed to fetch user for #{token_name}: #{e.message}")
      end
    end
  end
end

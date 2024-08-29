# frozen_string_literal: true

module Atlassian
  module JiraConnect
    class Client < Gitlab::HTTP
      def self.generate_update_sequence_id
        (Time.now.utc.to_f * 1000).round
      end

      def initialize(base_uri, shared_secret)
        @base_uri = base_uri
        @shared_secret = shared_secret
      end

      def send_info(project:, update_sequence_id: nil, **args)
        common = { project: project, update_sequence_id: update_sequence_id }
        dev_info = args.slice(:commits, :branches, :merge_requests)
        build_info = args.slice(:pipelines)
        deploy_info = args.slice(:deployments)
        remove_branch_info = args.slice(:remove_branch_info)
        ff_info = args.slice(:feature_flags)

        responses = []

        responses << store_dev_info(**common, **dev_info) if dev_info.present?
        responses << store_build_info(**common, **build_info) if build_info.present?
        responses << store_deploy_info(**common, **deploy_info) if deploy_info.present?
        responses << remove_branch_info(**common, **remove_branch_info) if remove_branch_info.present?
        responses << store_ff_info(**common, **ff_info) if ff_info.present?
        raise ArgumentError, 'Invalid arguments' if responses.empty?

        responses.compact
      end

      # Fetch user information for the given account.
      # https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-users/#api-rest-api-3-user-get
      def user_info(account_id)
        r = get('/rest/api/3/user', { accountId: account_id, expand: 'groups' })

        JiraUser.new(r.parsed_response) if r.code == 200
      end

      private

      def get(path, query_params)
        uri = URI.join(@base_uri, path)
        uri.query = URI.encode_www_form(query_params)

        self.class.get(uri, headers: headers(uri, 'GET'))
      end

      def store_ff_info(project:, feature_flags:, **opts)
        items = feature_flags.map { |flag| ::Atlassian::JiraConnect::Serializers::FeatureFlagEntity.represent(flag, opts) }
        items.reject! { |item| item.issue_keys.empty? }

        return if items.empty?

        r = post('/rest/featureflags/0.1/bulk', {
          flags: items,
          properties: { projectId: "project-#{project.id}" }
        })

        handle_response(r, 'feature flags') do |data|
          failed = data['failedFeatureFlags']
          if failed.present?
            errors = failed.flat_map do |k, errs|
              errs.map { |e| "#{k}: #{e['message']}" }
            end
            { 'errorMessages' => errors }
          end
        end
      end

      def store_deploy_info(project:, deployments:, **opts)
        items = deployments.map { |d| ::Atlassian::JiraConnect::Serializers::DeploymentEntity.represent(d, opts) }
        items.select! { |d| d.associations.present? }

        return if items.empty?

        r = post('/rest/deployments/0.1/bulk', { deployments: items })
        handle_response(r, 'deployments') { |data| errors(data, 'rejectedDeployments', r) }
      end

      def store_build_info(project:, pipelines:, update_sequence_id: nil)
        builds = pipelines.map do |pipeline|
          build = ::Atlassian::JiraConnect::Serializers::BuildEntity.represent(
            pipeline,
            update_sequence_id: update_sequence_id
          )
          next if build.issue_keys.empty?

          build
        end.compact
        return if builds.empty?

        r = post('/rest/builds/0.1/bulk', { builds: builds })
        handle_response(r, 'builds') { |data| errors(data, 'rejectedBuilds', r) }
      end

      def store_dev_info(project:, commits: nil, branches: nil, merge_requests: nil, update_sequence_id: nil)
        repo = ::Atlassian::JiraConnect::Serializers::RepositoryEntity.represent(
          project,
          commits: commits,
          branches: branches,
          merge_requests: merge_requests,
          user_notes_count: user_notes_count(merge_requests),
          update_sequence_id: update_sequence_id
        )

        post('/rest/devinfo/0.10/bulk', { repositories: [repo] })
      end

      def remove_branch_info(project:, remove_branch_info:, update_sequence_id: nil)
        # converts the branch name passed as remove_branch_info into a hexdecimal as per
        # jira's process. Note: we use the hexdigest method in the serializer to parse the id from the branch name
        # see ../lib/atlassian/jira_connect/serializers/branch_entity.rb#L8
        jira_branch_id = Digest::SHA256.hexdigest(remove_branch_info)

        logger.info({ message: "deleting jira branch id: #{jira_branch_id}, gitlab branch name: #{remove_branch_info}" })

        delete("/rest/devinfo/0.10/repository/#{project.id}/branch/#{jira_branch_id}")
      end

      def post(path, payload)
        uri = URI.join(@base_uri, path)

        self.class.post(uri, headers: headers(uri), body: metadata.merge(payload).to_json)
      end

      def delete(path)
        uri = URI.join(@base_uri, path)

        self.class.delete(uri, headers: headers(uri, 'DELETE'))
      end

      def headers(uri, http_method = 'POST')
        {
          'Authorization' => "JWT #{jwt_token(http_method, uri)}",
          'Content-Type' => 'application/json',
          'Accept' => 'application/json'
        }
      end

      def metadata
        { providerMetadata: { product: "GitLab #{Gitlab::VERSION}" } }
      end

      def handle_response(response, name, &block)
        data = response.parsed_response

        if [200, 202].include?(response.code)
          yield data
        else
          case response.code
          when 400 then { 'errorMessages' => data.map { |e| e['message'] } }
          when 401 then { 'errorMessages' => ['Invalid JWT'] }
          when 403 then { 'errorMessages' => ["App does not support #{name}"] }
          when 413 then { 'errorMessages' => ['Data too large'] + data.map { |e| e['message'] } }
          when 429 then { 'errorMessages' => ['Rate limit exceeded'] }
          when 503 then { 'errorMessages' => ['Service unavailable'] }
          else
            { 'errorMessages' => ['Unknown error'], 'response' => data }
          end.merge('responseCode' => response.code)
        end
      end

      def errors(data, key, response)
        messages = if data[key].present?
                     data[key].flat_map do |rejection|
                       rejection['errors'].map { |e| e['message'] }
                     end
                   else
                     []
                   end

        { 'errorMessages' => messages, 'responseCode' => response.code, 'requestBody' => request_body_schema(response) }
      end

      def request_body_schema(response)
        Oj.load(response.request.raw_body)
      rescue Oj::ParseError, EncodingError, Encoding::UndefinedConversionError
        'Request body includes invalid JSON'
      end

      def user_notes_count(merge_requests)
        return unless merge_requests

        Note.count_for_collection(merge_requests.map(&:id), 'MergeRequest').to_h do |count_group|
          [count_group.noteable_id, count_group.count]
        end
      end

      def jwt_token(http_method, uri)
        claims = Atlassian::Jwt.build_claims(
          Atlassian::JiraConnect.app_key,
          uri,
          http_method,
          @base_uri
        )

        Atlassian::Jwt.encode(claims, @shared_secret)
      end

      def logger
        Gitlab::IntegrationsLogger
      end
    end
  end
end

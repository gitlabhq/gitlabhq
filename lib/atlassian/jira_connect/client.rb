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
        ff_info = args.slice(:feature_flags)

        responses = []

        responses << store_dev_info(**common, **dev_info) if dev_info.present?
        responses << store_build_info(**common, **build_info) if build_info.present?
        responses << store_deploy_info(**common, **deploy_info) if deploy_info.present?
        responses << store_ff_info(**common, **ff_info) if ff_info.present?
        raise ArgumentError, 'Invalid arguments' if responses.empty?

        responses.compact
      end

      private

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
        items.reject! { |d| d.issue_keys.empty? }

        return if items.empty?

        r = post('/rest/deployments/0.1/bulk', { deployments: items })
        handle_response(r, 'deployments') { |data| errors(data, 'rejectedDeployments') }
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
        handle_response(r, 'builds') { |data| errors(data, 'rejectedBuilds') }
      end

      def store_dev_info(project:, commits: nil, branches: nil, merge_requests: nil, update_sequence_id: nil)
        repo = Serializers::RepositoryEntity.represent(
          project,
          commits: commits,
          branches: branches,
          merge_requests: merge_requests,
          user_notes_count: user_notes_count(merge_requests),
          update_sequence_id: update_sequence_id
        )

        post('/rest/devinfo/0.10/bulk', { repositories: [repo] })
      end

      def post(path, payload)
        uri = URI.join(@base_uri, path)

        self.class.post(uri, headers: headers(uri), body: metadata.merge(payload).to_json)
      end

      def headers(uri)
        {
          'Authorization' => "JWT #{jwt_token('POST', uri)}",
          'Content-Type' => 'application/json'
        }
      end

      def metadata
        { providerMetadata: { product: "GitLab #{Gitlab::VERSION}" } }
      end

      def handle_response(response, name, &block)
        data = response.parsed_response

        case response.code
        when 200 then yield data
        when 400 then { 'errorMessages' => data.map { |e| e['message'] } }
        when 401 then { 'errorMessages' => ['Invalid JWT'] }
        when 403 then { 'errorMessages' => ["App does not support #{name}"] }
        when 413 then { 'errorMessages' => ['Data too large'] + data.map { |e| e['message'] } }
        when 429 then { 'errorMessages' => ['Rate limit exceeded'] }
        when 503 then { 'errorMessages' => ['Service unavailable'] }
        else
          { 'errorMessages' => ['Unknown error'], 'response' => data }
        end
      end

      def errors(data, key)
        messages = if data[key].present?
                     data[key].flat_map do |rejection|
                       rejection['errors'].map { |e| e['message'] }
                     end
                   else
                     []
                   end

        { 'errorMessages' => messages }
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
    end
  end
end

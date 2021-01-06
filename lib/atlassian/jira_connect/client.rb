# frozen_string_literal: true

module Atlassian
  module JiraConnect
    class Client < Gitlab::HTTP
      def self.generate_update_sequence_id
        Gitlab::Metrics::System.monotonic_time.to_i
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

        responses = []

        responses << store_dev_info(**common, **dev_info) if dev_info.present?
        responses << store_build_info(**common, **build_info) if build_info.present?
        responses << store_deploy_info(**common, **deploy_info) if deploy_info.present?
        raise ArgumentError, 'Invalid arguments' if responses.empty?

        responses.compact
      end

      private

      def store_deploy_info(project:, deployments:, **opts)
        return unless Feature.enabled?(:jira_sync_deployments, project)

        items = deployments.map { |d| Serializers::DeploymentEntity.represent(d, opts) }
        items.reject! { |d| d.issue_keys.empty? }

        return if items.empty?

        post('/rest/deployments/0.1/bulk', { deployments: items })
      end

      def store_build_info(project:, pipelines:, update_sequence_id: nil)
        return unless Feature.enabled?(:jira_sync_builds, project)

        builds = pipelines.map do |pipeline|
          build = Serializers::BuildEntity.represent(
            pipeline,
            update_sequence_id: update_sequence_id
          )
          next if build.issue_keys.empty?

          build
        end.compact
        return if builds.empty?

        post('/rest/builds/0.1/bulk', { builds: builds })
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

      def user_notes_count(merge_requests)
        return unless merge_requests

        Note.count_for_collection(merge_requests.map(&:id), 'MergeRequest').map do |count_group|
          [count_group.noteable_id, count_group.count]
        end.to_h
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

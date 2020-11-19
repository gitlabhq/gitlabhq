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

      def store_dev_info(project:, commits: nil, branches: nil, merge_requests: nil, update_sequence_id: nil)
        dev_info_json = {
          repositories: [
            Serializers::RepositoryEntity.represent(
              project,
              commits: commits,
              branches: branches,
              merge_requests: merge_requests,
              user_notes_count: user_notes_count(merge_requests),
              update_sequence_id: update_sequence_id
            )
          ]
        }.to_json

        uri = URI.join(@base_uri, '/rest/devinfo/0.10/bulk')

        headers = {
          'Authorization' => "JWT #{jwt_token('POST', uri)}",
          'Content-Type' => 'application/json'
        }

        self.class.post(uri, headers: headers, body: dev_info_json)
      end

      private

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

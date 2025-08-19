# frozen_string_literal: true

module API
  module Helpers
    module KasHelpers
      FEATURE_FLAG_HEADER_NAME = 'Gitlab-Feature-Flag'

      def authenticate_gitlab_kas_request!
        render_api_error!('KAS JWT authentication invalid', 401) unless Gitlab::Kas.verify_api_request(headers)
      end

      def gitaly_info(project)
        Gitlab::GitalyClient.connection_data(project.repository_storage)
      end

      def gitaly_repository(project)
        project.repository.gitaly_repository.to_h
      end

      def set_feature_flag_header(user: nil, project: nil, group: nil)
        # set feature flag headers
        feature_flags = ::Feature::Kas.server_feature_flags_for_http_response(
          user: ::Feature::Kas.user_actor(user),
          project: ::Feature::Kas.project_actor(project),
          group: ::Feature::Kas.group_actor(group)
        )
        header FEATURE_FLAG_HEADER_NAME, feature_flags.map { |k, v| "#{k}=#{v}" }.join(', ')
      end

      def set_feature_flag_header_for_agent(user: nil, agent: nil)
        # set feature flag headers
        feature_flags = ::Feature::Kas.server_feature_flags_for_http_response(
          user: ::Feature::Kas.user_actor(user),
          project: ::Feature::Kas.project_actor(agent),
          group: ::Feature::Kas.group_actor(agent)
        )
        header FEATURE_FLAG_HEADER_NAME, feature_flags.map { |k, v| "#{k}=#{v}" }.join(', ')
      end
    end
  end
end

# frozen_string_literal: true

module API
  class Unleash < ::API::Base
    include PaginationParams

    feature_category :feature_flags

    namespace :feature_flags do
      resource :unleash, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        params do
          requires :project_id, type: String, desc: 'The ID of a project'
          optional :instance_id, type: String, desc: 'The Instance ID of Unleash Client'
          optional :app_name, type: String, desc: 'The Application Name of Unleash Client'
        end
        route_param :project_id do
          before do
            authorize_by_unleash_instance_id!
          end

          get do
            # not supported yet
            status :ok
          end

          desc 'Get a list of features (deprecated, v2 client support)'
          get 'features' do
            if ::Feature.enabled?(:cache_unleash_client_api, project)
              present_feature_flags
            else
              present :version, 1
              present :features, feature_flags, with: ::API::Entities::UnleashFeature
            end
          end

          # We decrease the urgency of this endpoint until the maxmemory issue of redis-cache has been resolved.
          # See https://gitlab.com/gitlab-org/gitlab/-/issues/365575#note_1033611872 for more information.
          desc 'Get a list of features'
          get 'client/features', urgency: :low do
            if ::Feature.enabled?(:cache_unleash_client_api, project)
              present_feature_flags
            else
              present :version, 1
              present :features, feature_flags, with: ::API::Entities::UnleashFeature
            end
          end

          post 'client/register' do
            # not supported yet
            status :ok
          end

          post 'client/metrics' do
            # not supported yet
            status :ok
          end
        end
      end
    end

    helpers do
      def present_feature_flags
        present_cached feature_flags_client,
          with: ::API::Entities::Unleash::ClientFeatureFlags,
          cache_context: -> (client) { client.unleash_api_cache_key }
      end

      def project
        @project ||= find_project(params[:project_id])
      end

      def feature_flags_client
        strong_memoize(:feature_flags_client) do
          client = Operations::FeatureFlagsClient.find_for_project_and_token(project, unleash_instance_id)
          client.unleash_app_name = unleash_app_name if client
          client
        end
      end

      def unleash_instance_id
        env['HTTP_UNLEASH_INSTANCEID'] || params[:instance_id]
      end

      def unleash_app_name
        env['HTTP_UNLEASH_APPNAME'] || params[:app_name]
      end

      def authorize_by_unleash_instance_id!
        unauthorized! unless feature_flags_client
      end

      def feature_flags
        return [] unless unleash_app_name.present?

        Operations::FeatureFlag.for_unleash_client(project, unleash_app_name)
      end
    end
  end
end

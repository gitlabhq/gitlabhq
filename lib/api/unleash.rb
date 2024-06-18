# frozen_string_literal: true

module API
  class Unleash < ::API::Base
    include PaginationParams

    unleash_tags = %w[unleash_api]

    feature_category :feature_flags

    namespace :feature_flags do
      resource :unleash, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        params do
          requires :project_id, type: String, desc: 'The ID of a project'
          optional :instance_id, type: String, desc: 'The instance ID of Unleash Client'
          optional :app_name, type: String, desc: 'The application name of Unleash Client'
        end
        route_param :project_id do
          before do
            authorize_by_unleash_instance_id!
          end

          get do
            # not supported yet
            status :ok
          end

          desc 'Get a list of features (deprecated, v2 client support)' do
            is_array true
            tags unleash_tags
          end
          get 'features', urgency: :low do
            present_feature_flags
          end

          desc 'Get a list of features' do
            is_array true
            tags unleash_tags
          end
          get 'client/features', urgency: :medium do
            present_feature_flags
          end

          post 'client/register' do
            # not supported yet
            status :ok
          end

          post 'client/metrics', urgency: :low do
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
          cache_context: ->(client) { client.unleash_api_cache_key }
      end

      def feature_flags_client
        strong_memoize(:feature_flags_client) do
          client = Operations::FeatureFlagsClient.find_for_project_and_token(params[:project_id], unleash_instance_id)
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
    end
  end
end

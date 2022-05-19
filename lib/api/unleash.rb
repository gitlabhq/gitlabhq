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
            present :version, 1
            present :features, feature_flags, with: ::API::Entities::UnleashFeature
          end

          desc 'Get a list of features'
          get 'client/features' do
            present :version, 1
            present :features, feature_flags, with: ::API::Entities::UnleashFeature
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
      def project
        @project ||= find_project(params[:project_id])
      end

      def unleash_instance_id
        env['HTTP_UNLEASH_INSTANCEID'] || params[:instance_id]
      end

      def unleash_app_name
        env['HTTP_UNLEASH_APPNAME'] || params[:app_name]
      end

      def authorize_by_unleash_instance_id!
        unauthorized! unless Operations::FeatureFlagsClient
          .find_for_project_and_token(project, unleash_instance_id)
      end

      def feature_flags
        return [] unless unleash_app_name.present?

        Operations::FeatureFlag.for_unleash_client(project, unleash_app_name)
      end
    end
  end
end

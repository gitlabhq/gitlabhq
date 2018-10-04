module API
  class Unleash < Grape::API
    include PaginationParams

    namespace :feature_flags do
      resource :unleash, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
        params do
          requires :project_id, type: String, desc: 'The ID of a project'
          optional :instance_id, type: String, desc: 'The Instance ID of Unleash Client'
        end
        route_param :project_id do
          before do
            authorize_by_unleash_instance_id!
            authorize_feature_flags_feature!
          end

          get do
            # not supported yet
            status :ok
          end

          get 'features' do
            present project, with: ::EE::API::Entities::UnleashFeatures
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
        params[:instance_id] || env['HTTP_UNLEASH_INSTANCEID']
      end

      def authorize_by_unleash_instance_id!
        unauthorized! unless Operations::FeatureFlagsClient
          .find_for_project_and_token(project, unleash_instance_id)
      end

      def authorize_feature_flags_feature!
        forbidden! unless project.feature_available?(:feature_flags)
      end
    end
  end
end

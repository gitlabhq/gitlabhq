module API
  class Unleash < Grape::API
    include PaginationParams

    namespace :feature_flags do
      resource :unleash, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
        params do
          requires :project_id, type: String, desc: 'The ID of a project'
          optional :instanceid, type: String, desc: 'The Instance ID of Unleash Client'
        end
        route_param :project_id do
          before do
            authenticate_by_unleash_instanceid!
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

      def unleash_instanceid
        params[:instanceid] || env['HTTP_UNLEASH_INSTANCEID']
      end

      def authenticate_by_unleash_instanceid!
        unauthorized! unless Operations::FeatureFlagsClient
          .find_for_project_and_token(project, unleash_instanceid)
      end
    end
  end
end

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
            authenticate_by_unleash_access_token!
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
        params[:instanceid] || env[:HTTP_UNLEASH_INSTANCEID]
      end

      def unleash_access_token
        return unless unleash_instanceid
        return unless project

        @unleash_access_token ||= Operations::FeatureFlagsAccessToken.find_by(
          token: unleash_instanceid, project: project)
      end

      def authenticate_by_unleash_access_token!
        unauthorized! unless unleash_access_token
      end
    end
  end
end

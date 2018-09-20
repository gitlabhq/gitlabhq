module API
  class FeatureFlags < Grape::API
    include PaginationParams

    resource :feature_flags do
      resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
        params do
          requires :id, type: String, desc: 'The ID of a project'
        end
        route_param :id do
          resource :unleash do
            before do
              authenticate_by_unleash_access_token!
            end

            get 'features' do
              present project, with: Entities::UnleashFeatures
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
          @project ||= find_project(params[:id])
        end

        def unleash_instanceid
          params[:instanceid] || env[:HTTP_UNLEASH_INSTANCEID]
        end

        def authenticate_by_unleash_access_token!
          unless Operations::FeatureFlagsAccessToken.find_by(token: unleash_instanceid, project: project)
            unauthorized!
          end
        end
      end
    end
  end
end

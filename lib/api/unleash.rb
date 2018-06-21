module API
  class Unleash < Grape::API
    include PaginationParams

    #before { authenticate! }

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
      get ':id/unleash/features' do
        issues = IssuesFinder.new(current_user, project_id: user_project.id, label_name: 'rollout')
        present issues, with: Entities::UnleashFeatureResponse
      end

      post ':id/unleash/client/register' do
        status :ok
      end

      post ':id/unleash/client/metrics' do
        status :ok
      end
    end
  end
end

# frozen_string_literal: true

module API
  class DeployTokens < Grape::API
    include PaginationParams

    before { authenticated_as_admin! }

    desc 'Return all deploy tokens' do
      detail 'This feature was introduced in GitLab 12.9.'
      success Entities::DeployToken
    end
    params do
      use :pagination
    end
    get 'deploy_tokens' do
      present paginate(DeployToken.all), with: Entities::DeployToken
    end
  end
end

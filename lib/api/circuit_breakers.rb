# frozen_string_literal: true

module API
  class CircuitBreakers < Grape::API
    before { authenticated_as_admin! }

    resource :circuit_breakers do
      params do
        requires :type,
                 type: String,
                 desc: "The type of circuitbreaker",
                 values: ['repository_storage']
      end
      resource ':type' do
        namespace '', requirements: { type: 'repository_storage' } do
          desc 'Get all git storages' do
            detail 'This feature was introduced in GitLab 9.5'
          end
          get do
            present []
          end

          desc 'Get all failing git storages' do
            detail 'This feature was introduced in GitLab 9.5'
          end
          get 'failing' do
            present []
          end

          desc 'Reset all storage failures and open circuitbreaker' do
            detail 'This feature was introduced in GitLab 9.5'
          end
          delete do
          end
        end
      end
    end
  end
end

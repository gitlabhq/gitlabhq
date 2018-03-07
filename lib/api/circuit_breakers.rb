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
          helpers do
            def failing_storage_health
              @failing_storage_health ||= Gitlab::Git::Storage::Health.for_failing_storages
            end

            def storage_health
              @storage_health ||= Gitlab::Git::Storage::Health.for_all_storages
            end
          end

          desc 'Get all git storages' do
            detail 'This feature was introduced in GitLab 9.5'
            success Entities::RepositoryStorageHealth
          end
          get do
            present storage_health, with: Entities::RepositoryStorageHealth
          end

          desc 'Get all failing git storages' do
            detail 'This feature was introduced in GitLab 9.5'
            success Entities::RepositoryStorageHealth
          end
          get 'failing' do
            present failing_storage_health, with: Entities::RepositoryStorageHealth
          end

          desc 'Reset all storage failures and open circuitbreaker' do
            detail 'This feature was introduced in GitLab 9.5'
          end
          delete do
            Gitlab::Git::Storage::FailureInfo.reset_all!
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module API
  class ProjectRepositoryStorageMoves < ::API::Base
    include PaginationParams

    before { authenticated_as_admin! }

    feature_category :gitaly

    resource :project_repository_storage_moves do
      desc 'Get a list of all project repository storage moves' do
        detail 'This feature was introduced in GitLab 13.0.'
        success Entities::Projects::RepositoryStorageMove
      end
      params do
        use :pagination
      end
      get do
        storage_moves = ::Projects::RepositoryStorageMove.with_projects.order_created_at_desc

        present paginate(storage_moves), with: Entities::Projects::RepositoryStorageMove, current_user: current_user
      end

      desc 'Get a project repository storage move' do
        detail 'This feature was introduced in GitLab 13.0.'
        success Entities::Projects::RepositoryStorageMove
      end
      params do
        requires :repository_storage_move_id, type: Integer, desc: 'The ID of a project repository storage move'
      end
      get ':repository_storage_move_id' do
        storage_move = ::Projects::RepositoryStorageMove.find(params[:repository_storage_move_id])

        present storage_move, with: Entities::Projects::RepositoryStorageMove, current_user: current_user
      end

      desc 'Schedule bulk project repository storage moves' do
        detail 'This feature was introduced in GitLab 13.7.'
      end
      params do
        requires :source_storage_name, type: String, desc: 'The source storage shard', values: -> { Gitlab.config.repositories.storages.keys }
        optional :destination_storage_name, type: String, desc: 'The destination storage shard', values: -> { Gitlab.config.repositories.storages.keys }
      end
      post do
        ::Projects::ScheduleBulkRepositoryShardMovesService.enqueue(
          declared_params[:source_storage_name],
          declared_params[:destination_storage_name]
        )

        accepted!
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get a list of all project repository storage moves' do
        detail 'This feature was introduced in GitLab 13.1.'
        success Entities::Projects::RepositoryStorageMove
      end
      params do
        use :pagination
      end
      get ':id/repository_storage_moves' do
        storage_moves = user_project.repository_storage_moves.with_projects.order_created_at_desc

        present paginate(storage_moves), with: Entities::Projects::RepositoryStorageMove, current_user: current_user
      end

      desc 'Get a project repository storage move' do
        detail 'This feature was introduced in GitLab 13.1.'
        success Entities::Projects::RepositoryStorageMove
      end
      params do
        requires :repository_storage_move_id, type: Integer, desc: 'The ID of a project repository storage move'
      end
      get ':id/repository_storage_moves/:repository_storage_move_id' do
        storage_move = user_project.repository_storage_moves.find(params[:repository_storage_move_id])

        present storage_move, with: Entities::Projects::RepositoryStorageMove, current_user: current_user
      end

      desc 'Schedule a project repository storage move' do
        detail 'This feature was introduced in GitLab 13.1.'
        success Entities::Projects::RepositoryStorageMove
      end
      params do
        optional :destination_storage_name, type: String, desc: 'The destination storage shard'
      end
      post ':id/repository_storage_moves' do
        storage_move = user_project.repository_storage_moves.build(
          declared_params.merge(source_storage_name: user_project.repository_storage)
        )

        if storage_move.schedule
          present storage_move, with: Entities::Projects::RepositoryStorageMove, current_user: current_user
        else
          render_validation_error!(storage_move)
        end
      end
    end
  end
end

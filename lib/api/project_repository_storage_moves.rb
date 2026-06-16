# frozen_string_literal: true

module API
  class ProjectRepositoryStorageMoves < ::API::Base
    include PaginationParams

    before { authenticated_as_admin! }

    feature_category :gitaly

    helpers do
      extend ::Gitlab::Utils::Override

      # Allow to move projects in hidden/pending_delete state
      override :find_project_scopes
      def find_project_scopes
        Project
      end
    end

    resource :project_repository_storage_moves do
      desc 'List all project repository storage moves' do
        detail 'Lists all project repository storage moves.'
        tags ['storage_moves']
        is_array true
        success code: 200, model: Entities::Projects::RepositoryStorageMove
      end
      params do
        use :pagination
      end
      route_setting :authorization, permissions: :read_repository_storage_move, boundary_type: :instance
      get do
        storage_moves = ::Projects::RepositoryStorageMove.with_projects.order_created_at_desc

        present paginate(storage_moves), with: Entities::Projects::RepositoryStorageMove, current_user: current_user
      end

      desc 'Retrieve a project repository storage move' do
        detail 'Retrieves a specified project repository storage move.'
        tags ['storage_moves']
        success code: 200, model: Entities::Projects::RepositoryStorageMove
      end
      params do
        requires :repository_storage_move_id, type: Integer, desc: 'The ID of a project repository storage move'
      end
      route_setting :authorization, permissions: :read_repository_storage_move, boundary_type: :instance
      get ':repository_storage_move_id' do
        storage_move = ::Projects::RepositoryStorageMove.find(params[:repository_storage_move_id])

        present storage_move, with: Entities::Projects::RepositoryStorageMove, current_user: current_user
      end

      desc 'Create repository storage moves for all projects on a storage shard' do
        detail 'Creates repository storage moves for each project repository stored on the source storage shard. ' \
          'This endpoint migrates all projects at once.'
        tags ['storage_moves']
        success code: 202
      end

      # rubocop:disable API/ParameterValuesProc -- storage shards are instance-specific
      params do
        requires :source_storage_name, type: String, desc: 'The source storage shard', values: -> { Gitlab.config.repositories.storages.keys }
        optional :destination_storage_name, type: String, desc: 'The destination storage shard', values: -> { Gitlab.config.repositories.storages.keys }
      end
      # rubocop:enable API/ParameterValuesProc

      route_setting :authorization, permissions: :create_repository_storage_move, boundary_type: :instance
      post do
        ::Projects::ScheduleBulkRepositoryShardMovesService.enqueue(
          declared_params[:source_storage_name],
          declared_params[:destination_storage_name]
        )

        accepted!
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'List all repository storage moves for a project' do
        detail 'Lists all repository storage moves for a project.'
        tags ['storage_moves']
        is_array true
        success code: 200, model: Entities::Projects::RepositoryStorageMove
      end
      params do
        use :pagination
      end
      route_setting :authorization, permissions: :read_repository_storage_move, boundary_type: :project
      get ':id/repository_storage_moves' do
        storage_moves = user_project.repository_storage_moves.with_projects.order_created_at_desc

        present paginate(storage_moves), with: Entities::Projects::RepositoryStorageMove, current_user: current_user
      end

      desc 'Retrieve a repository storage move for a project' do
        detail 'Retrieves a specified repository storage move for a project.'
        tags ['storage_moves']
        success code: 200, model: Entities::Projects::RepositoryStorageMove
      end
      params do
        requires :repository_storage_move_id, type: Integer, desc: 'The ID of a project repository storage move'
      end
      route_setting :authorization, permissions: :read_repository_storage_move, boundary_type: :project
      get ':id/repository_storage_moves/:repository_storage_move_id' do
        storage_move = user_project.repository_storage_moves.find(params[:repository_storage_move_id])

        present storage_move, with: Entities::Projects::RepositoryStorageMove, current_user: current_user
      end

      desc 'Create a repository storage move for a project' do
        detail 'Creates a repository storage move for a specified project.'
        tags ['storage_moves']
        success code: 201, model: Entities::Projects::RepositoryStorageMove
      end
      params do
        optional :destination_storage_name, type: String, desc: 'The destination storage shard'
      end
      route_setting :authorization, permissions: :create_repository_storage_move, boundary_type: :project
      post ':id/repository_storage_moves' do
        storage_move = user_project.repository_storage_moves.build(
          declared_params.compact.merge(source_storage_name: user_project.repository_storage)
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

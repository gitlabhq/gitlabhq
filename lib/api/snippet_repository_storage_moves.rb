# frozen_string_literal: true

module API
  class SnippetRepositoryStorageMoves < ::API::Base
    include PaginationParams

    before { authenticated_as_admin! }

    feature_category :gitaly

    resource :snippet_repository_storage_moves do
      desc 'List all snippet repository storage moves' do
        detail 'Lists all snippet repository storage moves. By default, `GET` requests return 20 results at a time ' \
          'because the API results are paginated.'
        tags ['storage_moves']
        is_array true
        success code: 200, model: Entities::Snippets::RepositoryStorageMove
      end
      params do
        use :pagination
      end
      route_setting :authorization, permissions: :read_repository_storage_move, boundary_type: :instance
      get do
        storage_moves = ::Snippets::RepositoryStorageMove.order_created_at_desc

        present paginate(storage_moves), with: Entities::Snippets::RepositoryStorageMove, current_user: current_user
      end

      desc 'Retrieve a snippet repository storage move' do
        detail 'Retrieves a specified snippet repository storage move.'
        tags ['storage_moves']
        success code: 200, model: Entities::Snippets::RepositoryStorageMove
      end
      params do
        requires :repository_storage_move_id, type: Integer, desc: 'The ID of a snippet repository storage move'
      end
      route_setting :authorization, permissions: :read_repository_storage_move, boundary_type: :instance
      get ':repository_storage_move_id' do
        storage_move = ::Snippets::RepositoryStorageMove.find(params[:repository_storage_move_id])

        present storage_move, with: Entities::Snippets::RepositoryStorageMove, current_user: current_user
      end

      desc 'Schedule repository storage moves for all snippets on a storage shard' do
        detail 'Schedules repository storage moves for each snippet repository stored on the source storage shard. ' \
          'This endpoint migrates all snippets at once.'
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
        ::Snippets::ScheduleBulkRepositoryShardMovesService.enqueue(
          declared_params[:source_storage_name],
          declared_params[:destination_storage_name]
        )

        accepted!
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a snippet'
    end
    resource :snippets do
      helpers do
        def user_snippet
          @user_snippet ||= Snippet.find_by(id: params[:id]) # rubocop: disable CodeReuse/ActiveRecord
        end
      end

      before do
        not_found!('Snippet') unless user_snippet
      end

      desc 'List all repository storage moves for a snippet' do
        detail 'Lists all repository storage moves for a specified snippet. By default, `GET` requests return 20 ' \
          'results at a time because the API results are paginated.'
        tags ['storage_moves']
        is_array true
        success code: 200, model: Entities::Snippets::RepositoryStorageMove
      end
      params do
        use :pagination
      end
      route_setting :authorization, permissions: :read_repository_storage_move, boundary_type: :instance
      get ':id/repository_storage_moves' do
        storage_moves = user_snippet.repository_storage_moves.order_created_at_desc

        present paginate(storage_moves), with: Entities::Snippets::RepositoryStorageMove, current_user: current_user
      end

      desc 'Retrieve a repository storage move for a snippet' do
        detail 'Retrieves a repository storage move for a specified snippet.'
        tags ['storage_moves']
        success code: 200, model: Entities::Snippets::RepositoryStorageMove
      end
      params do
        requires :repository_storage_move_id, type: Integer, desc: 'The ID of a snippet repository storage move'
      end
      route_setting :authorization, permissions: :read_repository_storage_move, boundary_type: :instance
      get ':id/repository_storage_moves/:repository_storage_move_id' do
        storage_move = user_snippet.repository_storage_moves.find(params[:repository_storage_move_id])

        present storage_move, with: Entities::Snippets::RepositoryStorageMove, current_user: current_user
      end

      desc 'Schedule a repository storage move for a snippet' do
        detail 'Schedules a repository storage move for a specified snippet.'
        tags ['storage_moves']
        success code: 201, model: Entities::Snippets::RepositoryStorageMove
      end
      params do
        optional :destination_storage_name, type: String, desc: 'The destination storage shard'
      end
      route_setting :authorization, permissions: :create_repository_storage_move, boundary_type: :instance
      post ':id/repository_storage_moves' do
        storage_move = user_snippet.repository_storage_moves.build(
          declared_params.compact.merge(source_storage_name: user_snippet.repository_storage)
        )

        if storage_move.schedule
          present storage_move, with: Entities::Snippets::RepositoryStorageMove, current_user: current_user
        else
          render_validation_error!(storage_move)
        end
      end
    end
  end
end

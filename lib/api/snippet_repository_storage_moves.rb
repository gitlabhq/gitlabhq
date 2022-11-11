# frozen_string_literal: true

module API
  class SnippetRepositoryStorageMoves < ::API::Base
    include PaginationParams

    before { authenticated_as_admin! }

    feature_category :gitaly

    resource :snippet_repository_storage_moves do
      desc 'Get a list of all snippet repository storage moves' do
        detail 'This feature was introduced in GitLab 13.8.'
        is_array true
        success code: 200, model: Entities::Snippets::RepositoryStorageMove
      end
      params do
        use :pagination
      end
      get do
        storage_moves = ::Snippets::RepositoryStorageMove.order_created_at_desc

        present paginate(storage_moves), with: Entities::Snippets::RepositoryStorageMove, current_user: current_user
      end

      desc 'Get a snippet repository storage move' do
        detail 'This feature was introduced in GitLab 13.8.'
        success code: 200, model: Entities::Snippets::RepositoryStorageMove
      end
      params do
        requires :repository_storage_move_id, type: Integer, desc: 'The ID of a snippet repository storage move'
      end
      get ':repository_storage_move_id' do
        storage_move = ::Snippets::RepositoryStorageMove.find(params[:repository_storage_move_id])

        present storage_move, with: Entities::Snippets::RepositoryStorageMove, current_user: current_user
      end

      desc 'Schedule bulk snippet repository storage moves' do
        detail 'This feature was introduced in GitLab 13.8.'
        success code: 202
      end
      params do
        requires :source_storage_name, type: String, desc: 'The source storage shard', values: -> { Gitlab.config.repositories.storages.keys }
        optional :destination_storage_name, type: String, desc: 'The destination storage shard', values: -> { Gitlab.config.repositories.storages.keys }
      end
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

      desc 'Get a list of all snippets repository storage moves' do
        detail 'This feature was introduced in GitLab 13.8.'
        is_array true
        success code: 200, model: Entities::Snippets::RepositoryStorageMove
      end
      params do
        use :pagination
      end
      get ':id/repository_storage_moves' do
        storage_moves = user_snippet.repository_storage_moves.order_created_at_desc

        present paginate(storage_moves), with: Entities::Snippets::RepositoryStorageMove, current_user: current_user
      end

      desc 'Get a snippet repository storage move' do
        detail 'This feature was introduced in GitLab 13.8.'
        success code: 200, model: Entities::Snippets::RepositoryStorageMove
      end
      params do
        requires :repository_storage_move_id, type: Integer, desc: 'The ID of a snippet repository storage move'
      end
      get ':id/repository_storage_moves/:repository_storage_move_id' do
        storage_move = user_snippet.repository_storage_moves.find(params[:repository_storage_move_id])

        present storage_move, with: Entities::Snippets::RepositoryStorageMove, current_user: current_user
      end

      desc 'Schedule a snippet repository storage move' do
        detail 'This feature was introduced in GitLab 13.8.'
        success code: 201, model: Entities::Snippets::RepositoryStorageMove
      end
      params do
        optional :destination_storage_name, type: String, desc: 'The destination storage shard'
      end
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

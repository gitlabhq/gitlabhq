# frozen_string_literal: true

module API
  class ProjectRepositoryStorageMoves < Grape::API
    include PaginationParams

    before { authenticated_as_admin! }

    resource :project_repository_storage_moves do
      desc 'Get a list of all project repository storage moves' do
        detail 'This feature was introduced in GitLab 13.0.'
        success Entities::ProjectRepositoryStorageMove
      end
      params do
        use :pagination
      end
      get do
        storage_moves = ProjectRepositoryStorageMove.with_projects.order_created_at_desc

        present paginate(storage_moves), with: Entities::ProjectRepositoryStorageMove, current_user: current_user
      end

      desc 'Get a project repository storage move' do
        detail 'This feature was introduced in GitLab 13.0.'
        success Entities::ProjectRepositoryStorageMove
      end
      get ':id' do
        storage_move = ProjectRepositoryStorageMove.find(params[:id])

        present storage_move, with: Entities::ProjectRepositoryStorageMove, current_user: current_user
      end
    end
  end
end

# frozen_string_literal: true

module API
  class RemoteMirrors < Grape::API
    include PaginationParams

    before do
      # TODO: Remove flag: https://gitlab.com/gitlab-org/gitlab/issues/38121
      not_found! unless Feature.enabled?(:remote_mirrors_api, user_project)
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc "List the project's remote mirrors" do
        success Entities::RemoteMirror
      end
      params do
        use :pagination
      end
      get ':id/remote_mirrors' do
        unauthorized! unless can?(current_user, :admin_remote_mirror, user_project)

        present paginate(user_project.remote_mirrors),
          with: Entities::RemoteMirror
      end
    end
  end
end

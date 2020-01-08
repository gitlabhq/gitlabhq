# frozen_string_literal: true

module API
  class RemoteMirrors < Grape::API
    include PaginationParams

    before do
      # TODO: Remove flag: https://gitlab.com/gitlab-org/gitlab/issues/38121
      not_found! unless Feature.enabled?(:remote_mirrors_api, user_project)

      unauthorized! unless can?(current_user, :admin_remote_mirror, user_project)
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
        present paginate(user_project.remote_mirrors),
          with: Entities::RemoteMirror
      end

      desc 'Update the attributes of a single remote mirror' do
        success Entities::RemoteMirror
      end
      params do
        requires :mirror_id, type: String, desc: 'The ID of a remote mirror'
        optional :enabled, type: Boolean, desc: 'Determines if the mirror is enabled'
        optional :only_protected_branches, type: Boolean, desc: 'Determines if only protected branches are mirrored'
      end
      put ':id/remote_mirrors/:mirror_id' do
        mirror = user_project.remote_mirrors.find(params[:mirror_id])

        mirror_params = declared_params(include_missing: false)
        mirror_params[:id] = mirror_params.delete(:mirror_id)
        update_params = { remote_mirrors_attributes: mirror_params }

        result = ::Projects::UpdateService
          .new(user_project, current_user, update_params)
          .execute

        if result[:status] == :success
          present mirror.reset, with: Entities::RemoteMirror
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end
    end
  end
end

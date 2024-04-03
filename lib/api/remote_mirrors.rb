# frozen_string_literal: true

module API
  class RemoteMirrors < ::API::Base
    include PaginationParams
    helpers Helpers::RemoteMirrorsHelpers

    feature_category :source_code_management

    before do
      unauthorized! unless can?(current_user, :admin_remote_mirror, user_project)
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc "List the project's remote mirrors" do
        success code: 200, model: Entities::RemoteMirror
        is_array true
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[remote_mirrors]
      end
      params do
        use :pagination
      end
      get ':id/remote_mirrors' do
        present paginate(user_project.remote_mirrors),
          with: Entities::RemoteMirror
      end

      desc 'Get a single remote mirror' do
        success code: 200, model: Entities::RemoteMirror
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[remote_mirrors]
      end
      params do
        requires :mirror_id, type: String, desc: 'The ID of a remote mirror'
      end
      get ':id/remote_mirrors/:mirror_id' do
        mirror = user_project.remote_mirrors.find(params[:mirror_id])

        present mirror, with: Entities::RemoteMirror
      end

      desc 'Triggers a push mirror operation' do
        success code: 204
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[remote_mirrors]
      end
      params do
        requires :mirror_id, type: String, desc: 'The ID of a remote mirror'
      end
      post ':id/remote_mirrors/:mirror_id/sync' do
        mirror = user_project.remote_mirrors.find(params[:mirror_id])

        result = ::RemoteMirrors::SyncService.new(user_project, current_user).execute(mirror)

        if result.success?
          status :no_content
        else
          render_api_error!(result[:message], 400)
        end
      end

      desc 'Create remote mirror for a project' do
        success code: 201, model: Entities::RemoteMirror
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[remote_mirrors]
      end
      params do
        requires :url, type: String, desc: 'The URL for a remote mirror', documentation: { example: 'https://*****:*****@example.com/gitlab/example.git' }
        optional :enabled, type: Boolean, desc: 'Determines if the mirror is enabled', documentation: { example: false }
        optional :auth_method, type: String, desc: 'Determines the mirror authentication method',
                               values: %w[ssh_public_key password]
        optional :keep_divergent_refs, type: Boolean, desc: 'Determines if divergent refs are kept on the target',
                                       documentation: { example: false }
        use :mirror_branches_setting
      end
      post ':id/remote_mirrors' do
        create_params = declared_params(include_missing: false)
        verify_mirror_branches_setting(create_params)
        new_mirror = user_project.remote_mirrors.create(create_params)

        if new_mirror.persisted?
          present new_mirror, with: Entities::RemoteMirror
        else
          render_validation_error!(new_mirror)
        end
      end

      desc 'Update the attributes of a single remote mirror' do
        success code: 200, model: Entities::RemoteMirror
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[remote_mirrors]
      end
      params do
        requires :mirror_id, type: String, desc: 'The ID of a remote mirror'
        optional :enabled, type: Boolean, desc: 'Determines if the mirror is enabled', documentation: { example: true }
        optional :auth_method, type: String, desc: 'Determines the mirror authentication method'
        optional :keep_divergent_refs, type: Boolean, desc: 'Determines if divergent refs are kept on the target',
                                       documentation: { example: false }
        use :mirror_branches_setting
      end
      put ':id/remote_mirrors/:mirror_id' do
        mirror = user_project.remote_mirrors.find(params[:mirror_id])

        mirror_params = declared_params(include_missing: false)
        mirror_params[:id] = mirror_params.delete(:mirror_id)

        verify_mirror_branches_setting(mirror_params)
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

      desc 'Delete a single remote mirror' do
        detail 'This feature was introduced in GitLab 14.10'
        success code: 204
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[remote_mirrors]
      end
      params do
        requires :mirror_id, type: String, desc: 'The ID of a remote mirror'
      end
      delete ':id/remote_mirrors/:mirror_id' do
        mirror = user_project.remote_mirrors.find(params[:mirror_id])

        destroy_conditionally!(mirror) do
          mirror_params = declared_params(include_missing: false).merge(_destroy: 1)
          mirror_params[:id] = mirror_params.delete(:mirror_id)
          update_params = { remote_mirrors_attributes: mirror_params }

          # Note: We are using the update service to be consistent with how the controller handles deletion
          result = ::Projects::UpdateService.new(user_project, current_user, update_params).execute

          if result[:status] != :success
            render_api_error!(result[:message], 400)
          end
        end
      end
    end
  end
end

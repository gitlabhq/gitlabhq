# frozen_string_literal: true

module API
  class RemoteMirrors < ::API::Base
    include PaginationParams
    helpers Helpers::RemoteMirrorsHelpers

    feature_category :source_code_management

    before do
      unauthorized! unless can?(current_user, :admin_remote_mirror, user_project)
    end

    helpers do
      def find_remote_mirror
        user_project.remote_mirrors.find(params[:mirror_id])
      end
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
        mirror = find_remote_mirror

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
        mirror = find_remote_mirror

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
        service = ::RemoteMirrors::CreateService.new(
          user_project,
          current_user,
          declared_params(include_missing: false)
        )

        result = service.execute

        if result.success?
          present result.payload[:remote_mirror], with: Entities::RemoteMirror
        else
          render_api_error!(result.message, 400)
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
        mirror = find_remote_mirror

        service = ::RemoteMirrors::UpdateService.new(
          user_project,
          current_user,
          declared_params(include_missing: false)
        )

        result = service.execute(mirror)

        render_api_error!(result.message, 400) if result.error?

        present result.payload[:remote_mirror], with: Entities::RemoteMirror
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
        mirror = find_remote_mirror

        destroy_conditionally!(mirror) do
          result = ::RemoteMirrors::DestroyService.new(user_project, current_user).execute(mirror)

          render_api_error!(result.message, 400) if result.error?
        end
      end

      desc 'Get the public key of a single remote mirror' do
        success code: 200
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[remote_mirrors]
      end
      params do
        requires :mirror_id, type: String, desc: 'The ID of a remote mirror'
      end
      get ':id/remote_mirrors/:mirror_id/public_key' do
        mirror = find_remote_mirror

        not_found! unless mirror.ssh_key_auth?

        { public_key: mirror.ssh_public_key }
      end
    end
  end
end

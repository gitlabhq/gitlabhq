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

      def build_mirror_params(declared, url:)
        result = declared.dup
        return result unless result.key?(:host_keys)

        host_keys = result.delete(:host_keys)
        converter = ::RemoteMirrors::HostKeysConverter.new(host_keys, url: url)
        result[:ssh_known_hosts] = converter.to_ssh_known_hosts!

        result
      rescue ::RemoteMirrors::HostKeysConverter::InvalidHostKeyError => e
        render_api_error!(e.message, 400)
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: ::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'List all remote mirrors for a project' do
        detail 'Lists all remote mirrors for a specified project.'
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
      route_setting :authorization, permissions: :read_remote_mirror, boundary_type: :project
      get ':id/remote_mirrors' do
        present paginate(user_project.remote_mirrors),
          with: Entities::RemoteMirror
      end

      desc 'Retrieve a remote mirror for a project' do
        detail 'Retrieves a specified remote mirror for a project.'
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
      route_setting :authorization, permissions: :read_remote_mirror, boundary_type: :project
      get ':id/remote_mirrors/:mirror_id' do
        mirror = find_remote_mirror

        present mirror, with: Entities::RemoteMirror
      end

      desc 'Force push mirror update' do
        detail 'Forces an update to a push mirror.'
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
      route_setting :authorization, permissions: :sync_remote_mirror, boundary_type: :project
      post ':id/remote_mirrors/:mirror_id/sync' do
        mirror = find_remote_mirror

        result = ::RemoteMirrors::SyncService.new(user_project, current_user).execute(mirror)

        if result.success?
          status :no_content
        else
          render_api_error!(result[:message], 400)
        end
      end

      desc 'Create a push mirror' do
        detail 'Creates a push mirror.'
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
        use :host_key_params
      end
      route_setting :authorization, permissions: :create_remote_mirror, boundary_type: :project
      post ':id/remote_mirrors' do
        mirror_params = build_mirror_params(declared_params(include_missing: false), url: params[:url])

        service = ::RemoteMirrors::CreateService.new(
          user_project,
          current_user,
          mirror_params
        )

        result = service.execute

        if result.success?
          present result.payload[:remote_mirror], with: Entities::RemoteMirror
        else
          render_api_error!(result.message, 400)
        end
      end

      desc 'Update a remote mirror in a project' do
        detail 'Updates the configuration or operational status of a specified remote mirror.'
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
        use :host_key_params
      end
      route_setting :authorization, permissions: :update_remote_mirror, boundary_type: :project
      put ':id/remote_mirrors/:mirror_id' do
        mirror = find_remote_mirror
        mirror_params = build_mirror_params(declared_params(include_missing: false), url: mirror.url)

        service = ::RemoteMirrors::UpdateService.new(
          user_project,
          current_user,
          mirror_params
        )

        result = service.execute(mirror)

        render_api_error!(result.message, 400) if result.error?

        present result.payload[:remote_mirror], with: Entities::RemoteMirror
      end

      desc 'Delete a remote mirror from a project' do
        detail 'Deletes a specified remote mirror from a project.'
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
      route_setting :authorization, permissions: :delete_remote_mirror, boundary_type: :project
      delete ':id/remote_mirrors/:mirror_id' do
        mirror = find_remote_mirror

        destroy_conditionally!(mirror) do
          result = ::RemoteMirrors::DestroyService.new(user_project, current_user).execute(mirror)

          render_api_error!(result.message, 400) if result.error?
        end
      end

      desc 'Retrieve a public key for a remote mirror' do
        detail 'Retrieves the public key of a specified remote mirror that uses SSH authentication.'
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
      route_setting :authorization, permissions: :read_remote_mirror_public_key, boundary_type: :project
      get ':id/remote_mirrors/:mirror_id/public_key' do
        mirror = find_remote_mirror

        not_found! unless mirror.ssh_key_auth?

        { public_key: mirror.ssh_public_key }
      end
    end
  end
end

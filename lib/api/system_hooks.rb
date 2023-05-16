# frozen_string_literal: true

module API
  class SystemHooks < ::API::Base
    include PaginationParams

    system_hooks_tags = %w[system_hooks]

    feature_category :webhooks

    before do
      authenticate!
      authenticated_as_admin!
    end

    helpers ::API::Helpers::WebHooksHelpers

    helpers do
      def hook_scope
        SystemHook
      end

      params :hook_parameters do
        optional :token, type: String,
                         desc: "Secret token to validate received payloads; this isn't returned in the response"
        optional :push_events, type: Boolean, desc: 'When true, the hook fires on push events'
        optional :tag_push_events, type: Boolean, desc: 'When true, the hook fires on new tags being pushed'
        optional :merge_requests_events, type: Boolean, desc: 'Trigger hook on merge requests events'
        optional :repository_update_events, type: Boolean, desc: 'Trigger hook on repository update events'
        optional :enable_ssl_verification, type: Boolean, desc: 'Do SSL verification when triggering the hook'
        use :url_variables
      end
    end

    resource :hooks do
      mount ::API::Hooks::UrlVariables

      desc 'List system hooks' do
        detail 'Get a list of all system hooks'
        success Entities::Hook
        is_array true
        tags system_hooks_tags
      end
      params do
        use :pagination
      end
      get do
        present paginate(SystemHook.all), with: Entities::Hook
      end

      desc 'Get system hook' do
        detail 'Get a system hook by its ID. Introduced in GitLab 14.9.'
        success Entities::Hook
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags system_hooks_tags
      end
      params do
        requires :hook_id, type: Integer, desc: 'The ID of the system hook'
      end
      get ":hook_id" do
        present find_hook, with: Entities::Hook
      end

      desc 'Add new system hook' do
        detail 'Add a new system hook'
        success Entities::Hook
        failure [
          { code: 400, message: 'Validation error' },
          { code: 404, message: 'Not found' },
          { code: 422, message: 'Unprocessable entity' }
        ]
        tags system_hooks_tags
      end
      params do
        use :requires_url
        use :hook_parameters
      end
      post do
        hook_params = create_hook_params
        hook = SystemHook.new(hook_params)

        save_hook(hook, Entities::Hook)
      end

      desc 'Edit system hook' do
        detail 'Edits a system hook'
        success Entities::Hook
        failure [
          { code: 400, message: 'Validation error' },
          { code: 404, message: 'Not found' },
          { code: 422, message: 'Unprocessable entity' }
        ]
        tags system_hooks_tags
      end
      params do
        requires :hook_id, type: Integer, desc: 'The ID of the system hook'
        use :optional_url
        use :hook_parameters
      end
      put ":hook_id" do
        update_hook(entity: Entities::Hook)
      end

      mount ::API::Hooks::Test, with: {
        data: {
          event_name: "project_create",
          name: "Ruby",
          path: "ruby",
          project_id: 1,
          owner_name: "Someone",
          owner_email: "example@gitlabhq.com"
        },
        kind: 'system_hooks'
      }

      desc 'Delete system hook' do
        detail 'Deletes a system hook'
        success Entities::Hook
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags system_hooks_tags
      end
      params do
        requires :hook_id, type: Integer, desc: 'The ID of the system hook'
      end
      delete ":hook_id" do
        hook = find_hook

        destroy_conditionally!(hook) do
          WebHooks::DestroyService.new(current_user).execute(hook)
        end
      end
    end
  end
end

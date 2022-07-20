# frozen_string_literal: true

module API
  class SystemHooks < ::API::Base
    include PaginationParams

    feature_category :integrations

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
        optional :token, type: String, desc: 'The token used to validate payloads'
        optional :push_events, type: Boolean, desc: "Trigger hook on push events"
        optional :tag_push_events, type: Boolean, desc: "Trigger hook on tag push events"
        optional :merge_requests_events, type: Boolean, desc: "Trigger hook on tag push events"
        optional :repository_update_events, type: Boolean, desc: "Trigger hook on repository update events"
        optional :enable_ssl_verification, type: Boolean, desc: "Do SSL verification when triggering the hook"
        use :url_variables
      end
    end

    resource :hooks do
      mount ::API::Hooks::UrlVariables

      desc 'Get the list of system hooks' do
        success Entities::Hook
      end
      params do
        use :pagination
      end
      get do
        present paginate(SystemHook.all), with: Entities::Hook
      end

      desc 'Get a hook' do
        success Entities::Hook
      end
      params do
        requires :hook_id, type: Integer, desc: 'The ID of the system hook'
      end
      get ":hook_id" do
        present find_hook, with: Entities::Hook
      end

      desc 'Create a new system hook' do
        success Entities::Hook
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

      desc 'Update an existing system hook' do
        success Entities::Hook
      end
      params do
        requires :hook_id, type: Integer, desc: "The ID of the hook to update"
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

      desc 'Delete a hook' do
        success Entities::Hook
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

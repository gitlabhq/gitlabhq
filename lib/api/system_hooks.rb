# frozen_string_literal: true

module API
  class SystemHooks < ::API::Base
    include PaginationParams

    system_hooks_tags = %w[system_hooks]

    feature_category :webhooks

    before do
      authenticate!
      ability = route.request_method == 'GET' ? :read_web_hook : :admin_web_hook
      authorize! ability
    end

    helpers ::API::Helpers::WebHooksHelpers

    helpers do
      def hook_scope
        SystemHook
      end

      params :hook_parameters do
        optional :name, type: String, desc: 'Name of the hook'
        optional :description, type: String, desc: 'Description of the hook'
        optional :token, type: String,
          desc: "Secret token to validate received payloads; this isn't returned in the response"
        optional :push_events, type: Boolean, desc: 'When true, the hook fires on push events'
        optional :tag_push_events, type: Boolean, desc: 'When true, the hook fires on new tags being pushed'
        optional :merge_requests_events, type: Boolean, desc: 'Trigger hook on merge requests events'
        optional :repository_update_events, type: Boolean, desc: 'Trigger hook on repository update events'
        optional :enable_ssl_verification, type: Boolean, desc: 'Do SSL verification when triggering the hook'
        optional :push_events_branch_filter, type: String, desc: "Trigger hook on specified branch only"
        optional :branch_filter_strategy, type: String, values: WebHook.branch_filter_strategies.keys,
          desc: "Filter push events by branch. Possible values are `wildcard` (default), `regex`, and `all_branches`"
        use :url_variables
        use :custom_headers
      end
    end

    resource :hooks do
      mount ::API::Hooks::UrlVariables
      mount ::API::Hooks::CustomHeaders

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

        result = WebHooks::CreateService.new(current_user).execute(hook_params, hook_scope)

        if result[:status] == :success
          present result[:hook], with: Entities::Hook
        else
          error!(result.message, result.http_status || 422)
        end
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

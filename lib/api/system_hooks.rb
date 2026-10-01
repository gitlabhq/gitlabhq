# frozen_string_literal: true

module API
  class SystemHooks < ::API::Base
    include PaginationParams

    system_hooks_tags = %w[hooks]
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
        optional :name, type: String, desc: 'Name of the hook. ' \
                                        '[Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/460887) in ' \
                                        'GitLab 17.1.'
        optional :description, type: String,
          desc: 'Description of the hook. ' \
            '[Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/460887) in GitLab 17.1.'
        optional :token, type: String,
          desc: 'Secret token used to validate received payloads. Not returned in the response, and changing the ' \
            'hook URL resets it.'
        optional :signing_token, type: String,
          desc: 'HMAC signing token used to compute the `webhook-signature` header. Must be in `whsec_<base64>` ' \
            'format encoding a 32-byte key, and is not returned in the response. ' \
            '[Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231325) in GitLab 19.0.'
        optional :push_events, type: Boolean, desc: 'If `true`, triggers the system hook on push events.'
        optional :tag_push_events, type: Boolean, desc: 'If `true`, triggers the system hook on tag push events.'
        optional :merge_requests_events, type: Boolean, desc: 'If `true`, triggers the system hook on merge request ' \
                                                          'events.'
        optional :repository_update_events, type: Boolean, desc: 'If `true`, triggers the system hook on repository ' \
                                                             'update events.'
        optional :enable_ssl_verification, type: Boolean, desc: 'If `true`, verifies the SSL certificate when the ' \
                                                            'hook is triggered.'
        optional :push_events_branch_filter, type: String, desc: 'Filter push events by branch name.'
        optional :branch_filter_strategy, type: String, values: WebHook.branch_filter_strategies.keys,
          desc: 'Filter push events by branch. Defaults to `wildcard`.'
        optional :custom_webhook_template, type: String, desc: 'Custom template for the system hook request payload.'
        use :url_variables
        use :custom_headers
      end
    end

    resource :hooks do
      mount ::API::Hooks::UrlVariables, with: { boundary_type: :instance }
      mount ::API::Hooks::CustomHeaders, with: { boundary_type: :instance }

      desc 'List all system hooks' do
        detail 'Lists all system hooks for the instance.'
        success Entities::Hook
        is_array true
        tags system_hooks_tags
      end
      params do
        use :pagination
      end
      route_setting :authorization, permissions: :read_webhook, boundary_type: :instance, assignable_when: [:admin]
      get do
        present paginate(SystemHook.all), with: Entities::Hook
      end

      desc 'Retrieve a system hook' do
        detail 'Retrieves a specified system hook.'
        success Entities::Hook
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags system_hooks_tags
      end
      params do
        requires :hook_id, type: Integer, desc: 'ID of the system hook.'
      end
      route_setting :authorization, permissions: :read_webhook, boundary_type: :instance, assignable_when: [:admin]
      get ":hook_id" do
        present find_hook, with: Entities::Hook
      end

      desc 'Create a system hook' do
        detail 'Creates a system hook.'
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
      route_setting :authorization, permissions: :create_webhook, boundary_type: :instance, assignable_when: [:admin]
      post do
        hook_params = create_hook_params

        result = WebHooks::CreateService.new(current_user).execute(hook_params, hook_scope, Current.organization)

        if result[:status] == :success
          present result[:hook], with: Entities::Hook
        else
          error!(result.message, result.http_status || 422)
        end
      end

      desc 'Update a system hook' do
        detail 'Updates a specified system hook.'
        success Entities::Hook
        failure [
          { code: 400, message: 'Validation error' },
          { code: 404, message: 'Not found' },
          { code: 422, message: 'Unprocessable entity' }
        ]
        tags system_hooks_tags
      end
      route_setting :authorization, permissions: :update_webhook, boundary_type: :instance, assignable_when: [:admin]
      params do
        requires :hook_id, type: Integer, desc: 'ID of the system hook.'
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

      desc 'Delete a system hook' do
        detail 'Deletes a specified system hook. Administrators only.'
        success Entities::Hook
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags system_hooks_tags
      end
      params do
        requires :hook_id, type: Integer, desc: 'ID of the system hook.'
      end
      route_setting :authorization, permissions: :delete_webhook, boundary_type: :instance, assignable_when: [:admin]
      delete ":hook_id" do
        hook = find_hook

        destroy_conditionally!(hook) do
          WebHooks::DestroyService.new(current_user).execute(hook)
        end
      end
    end
  end
end

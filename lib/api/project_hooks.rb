# frozen_string_literal: true

module API
  class ProjectHooks < ::API::Base
    include PaginationParams

    project_hooks_tags = %w[hooks]
    before { authenticate! }
    before do
      ability = route.request_method == 'GET' ? :read_web_hook : :admin_web_hook
      authorize! ability, user_project
    end

    feature_category :webhooks
    urgency :low

    helpers ::API::Helpers::WebHooksHelpers

    helpers do
      def hook_scope
        user_project.hooks
      end

      def hook_container
        user_project
      end

      params :common_hook_parameters do
        optional :name, type: String,
          desc: 'Name of the project webhook. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/460887) ' \
            'in GitLab 17.1.'
        optional :description, type: String, desc: 'Description of the project webhook. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/460887) in GitLab 17.1.'
        optional :push_events, type: Boolean, desc: 'If `true`, triggers the project webhook on push events.'
        optional :issues_events, type: Boolean, desc: 'If `true`, triggers the project webhook on issue events.'
        optional :confidential_issues_events, type: Boolean, desc: 'If `true`, triggers the project webhook on confidential issue events.'
        optional :merge_requests_events, type: Boolean, desc: 'If `true`, triggers the project webhook on merge request events.'
        optional :tag_push_events, type: Boolean, desc: 'If `true`, triggers the project webhook on tag push events.'
        optional :note_events, type: Boolean, desc: 'If `true`, triggers the project webhook on note events.'
        optional :confidential_note_events, type: Boolean, desc: 'If `true`, triggers the project webhook on confidential note events.'
        optional :job_events, type: Boolean, desc: 'If `true`, triggers the project webhook on job events.'
        optional :pipeline_events, type: Boolean, desc: 'If `true`, triggers the project webhook on pipeline events.'
        optional :wiki_page_events, type: Boolean, desc: 'If `true`, triggers the project webhook on wiki page events.'
        optional :deployment_events, type: Boolean, desc: 'If `true`, triggers the project webhook on deployment events.'
        optional :feature_flag_events, type: Boolean, desc: 'If `true`, triggers the project webhook on feature flag events.'
        optional :releases_events, type: Boolean, desc: 'If `true`, triggers the project webhook on release events.'
        optional :milestone_events, type: Boolean, desc: 'If `true`, triggers the project webhook on milestone events.'
        optional :emoji_events, type: Boolean, desc: 'If `true`, triggers the project webhook on emoji events.'
        optional :resource_access_token_events, type: Boolean, desc: 'If `true`, triggers the project webhook on project access token expiry events.'
        optional :resource_deploy_token_events, type: Boolean, desc: 'If `true`, triggers the project webhook on project deploy token expiry events.'
        optional :enable_ssl_verification, type: Boolean, desc: 'If `true`, verifies the SSL certificate when the webhook is triggered.'
        optional :token, type: String, desc: 'Secret token used to validate received payloads. Not returned in the response, and changing the webhook URL resets it.'
        optional :signing_token, type: String,
          desc: 'HMAC signing token used to compute the `webhook-signature` header. Must be in ' \
            '`whsec_<base64>` format encoding a 32-byte key, and is not returned in the response. ' \
            '[Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/231325) in GitLab 19.0.'
        optional :push_events_branch_filter, type: String, desc: 'Filter push events by branch name.'
        optional :custom_webhook_template, type: String, desc: 'Custom template for the webhook request payload.'
        optional :branch_filter_strategy, type: String, values: WebHook.branch_filter_strategies.keys,
          desc: 'Filter push events by branch. Defaults to `wildcard`.'
        optional :vulnerability_events, type: Boolean, desc: 'If `true`, triggers the project webhook on vulnerability events.'
        optional :duo_flow_callback_enabled, type: Boolean,
          desc: "If `true`, allows Duo Agent Platform flows to send lifecycle and progress events to this " \
            "project webhook. A flow must reference the webhook's ID as `callback_hook_id` when it starts. " \
            "[Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/249149) in GitLab 19.4 " \
            "[with a feature flag](https://docs.gitlab.com/administration/feature_flags/) named " \
            "`duo_flow_callback_hooks`. Disabled by default."
        use :url_variables
        use :custom_headers
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'ID or URL-encoded path of the project.'
    end
    resource :projects, requirements: ::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      namespace ':id/hooks' do
        mount ::API::Hooks::UrlVariables, with: { boundary_type: :project }
        mount ::API::Hooks::CustomHeaders, with: { boundary_type: :project }
      end

      desc 'List all webhooks for a project' do
        detail 'Lists all webhooks for a specified project.'
        success Entities::ProjectHook
        is_array true
        tags project_hooks_tags
      end
      params do
        use :pagination
      end
      route_setting :authorization, permissions: :read_webhook, boundary_type: :project
      get ":id/hooks" do
        present paginate(user_project.hooks), with: Entities::ProjectHook, with_url_variables: false, with_custom_headers: false
      end

      params do
        requires :hook_id, type: Integer, desc: 'ID of the project webhook.'
      end
      namespace ":id/hooks/:hook_id/" do
        desc 'Retrieve a project webhook' do
          detail 'Retrieves a specified webhook for a project.'
          success Entities::ProjectHook
          failure [
            { code: 404, message: 'Not found' }
          ]
          tags project_hooks_tags
        end
        params do
          requires :hook_id, type: Integer, desc: 'ID of the project webhook.'
        end
        route_setting :authorization, permissions: :read_webhook, boundary_type: :project
        get do
          hook = user_project.hooks.find(params[:hook_id])
          present hook, with: Entities::ProjectHook
        end

        desc 'Update a project webhook' do
          detail 'Updates a specified webhook for a project.'
          success Entities::ProjectHook
          failure [
            { code: 400, message: 'Validation error' },
            { code: 404, message: 'Not found' },
            { code: 422, message: 'Unprocessable entity' }
          ]
          tags project_hooks_tags
        end
        params do
          requires :hook_id, type: Integer, desc: 'ID of the project webhook.'
          use :optional_url
          use :common_hook_parameters
        end
        route_setting :authorization, permissions: :update_webhook, boundary_type: :project
        put do
          update_hook(entity: Entities::ProjectHook)
        end

        desc 'Delete a project webhook' do
          detail 'Deletes a specified webhook for a project.'
          success Entities::ProjectHook
          failure [
            { code: 404, message: 'Not found' }
          ]
          tags project_hooks_tags
        end
        params do
          requires :hook_id, type: Integer, desc: 'ID of the project webhook.'
        end
        route_setting :authorization, permissions: :delete_webhook, boundary_type: :project
        delete do
          hook = find_hook

          destroy_conditionally!(hook) do
            WebHooks::DestroyService.new(current_user).execute(hook)
          end
        end

        mount ::API::Hooks::Events, with: { boundary_type: :project }
      end

      desc 'Add a webhook to a project' do
        detail 'Adds a webhook to a specified project.'
        success Entities::ProjectHook
        failure [
          { code: 400, message: 'Validation error' },
          { code: 404, message: 'Not found' },
          { code: 422, message: 'Unprocessable entity' }
        ]
        tags project_hooks_tags
      end
      params do
        use :requires_url
        use :common_hook_parameters
      end
      route_setting :authorization, permissions: :create_webhook, boundary_type: :project
      post ":id/hooks" do
        hook_params = create_hook_params

        result = WebHooks::CreateService.new(current_user).execute(hook_params, hook_scope)

        if result[:status] == :success
          present result[:hook], with: Entities::ProjectHook
        else
          error!(result.message, result.http_status || 422)
        end
      end

      namespace ':id/hooks/' do
        mount ::API::Hooks::TriggerTest, with: {
          entity: ProjectHook,
          boundary_type: :project
        }
        mount ::API::Hooks::ResendHook, with: { boundary_type: :project }
      end
    end
  end
end

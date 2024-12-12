# frozen_string_literal: true

module API
  class ProjectHooks < ::API::Base
    include PaginationParams

    project_hooks_tags = %w[project_hooks]

    before { authenticate! }
    before do
      ability = route.request_method == 'GET' ? :read_web_hook : :admin_web_hook
      authorize! ability, user_project
    end

    feature_category :webhooks

    helpers ::API::Helpers::WebHooksHelpers

    helpers do
      def hook_scope
        user_project.hooks
      end

      params :common_hook_parameters do
        optional :name, type: String, desc: 'Name of the hook'
        optional :description, type: String, desc: 'Description of the hook'
        optional :push_events, type: Boolean, desc: "Trigger hook on push events"
        optional :issues_events, type: Boolean, desc: "Trigger hook on issues events"
        optional :confidential_issues_events, type: Boolean, desc: "Trigger hook on confidential issues events"
        optional :merge_requests_events, type: Boolean, desc: "Trigger hook on merge request events"
        optional :tag_push_events, type: Boolean, desc: "Trigger hook on tag push events"
        optional :note_events, type: Boolean, desc: "Trigger hook on note (comment) events"
        optional :confidential_note_events, type: Boolean, desc: "Trigger hook on confidential note (comment) events"
        optional :job_events, type: Boolean, desc: "Trigger hook on job events"
        optional :pipeline_events, type: Boolean, desc: "Trigger hook on pipeline events"
        optional :wiki_page_events, type: Boolean, desc: "Trigger hook on wiki events"
        optional :deployment_events, type: Boolean, desc: "Trigger hook on deployment events"
        optional :feature_flag_events, type: Boolean, desc: "Trigger hook on feature flag events"
        optional :releases_events, type: Boolean, desc: "Trigger hook on release events"
        optional :emoji_events, type: Boolean, desc: "Trigger hook on emoji events"
        optional :resource_access_token_events, type: Boolean, desc: "Trigger hook on project access token expiry events"
        optional :enable_ssl_verification, type: Boolean, desc: "Do SSL verification when triggering the hook"
        optional :token, type: String, desc: "Secret token to validate received payloads; this will not be returned in the response"
        optional :push_events_branch_filter, type: String, desc: "Trigger hook on specified branch only"
        optional :custom_webhook_template, type: String, desc: "Custom template for the request payload"
        optional :branch_filter_strategy, type: String, values: WebHook.branch_filter_strategies.keys,
          desc: "Filter push events by branch. Possible values are `wildcard` (default), `regex`, and `all_branches`"
        optional :vulnerability_events, type: Boolean, desc: "Trigger hook on vulnerability events"
        use :url_variables
        use :custom_headers
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      namespace ':id/hooks' do
        mount ::API::Hooks::UrlVariables
        mount ::API::Hooks::CustomHeaders
      end

      desc 'List project hooks' do
        detail 'Get a list of project hooks'
        success Entities::ProjectHook
        is_array true
        tags project_hooks_tags
      end
      params do
        use :pagination
      end
      get ":id/hooks" do
        present paginate(user_project.hooks), with: Entities::ProjectHook, with_url_variables: false, with_custom_headers: false
      end

      namespace ":id/hooks/:hook_id/" do
        desc 'Get project hook' do
          detail 'Get a specific hook for a project'
          success Entities::ProjectHook
          failure [
            { code: 404, message: 'Not found' }
          ]
          tags project_hooks_tags
        end
        params do
          requires :hook_id, type: Integer, desc: 'The ID of a project hook'
        end
        get do
          hook = user_project.hooks.find(params[:hook_id])
          present hook, with: Entities::ProjectHook
        end

        desc 'Edit project hook' do
          detail 'Edits a hook for a specified project.'
          success Entities::ProjectHook
          failure [
            { code: 400, message: 'Validation error' },
            { code: 404, message: 'Not found' },
            { code: 422, message: 'Unprocessable entity' }
          ]
          tags project_hooks_tags
        end
        params do
          requires :hook_id, type: Integer, desc: 'The ID of the project hook'
          use :optional_url
          use :common_hook_parameters
        end
        put do
          update_hook(entity: Entities::ProjectHook)
        end

        desc 'Delete a project hook' do
          detail 'Removes a hook from a project. This is an idempotent method and can be called multiple times. Either the hook is available or not.'
          success Entities::ProjectHook
          failure [
            { code: 404, message: 'Not found' }
          ]
          tags project_hooks_tags
        end
        params do
          requires :hook_id, type: Integer, desc: 'The ID of the project hook'
        end
        delete do
          hook = find_hook

          destroy_conditionally!(hook) do
            WebHooks::DestroyService.new(current_user).execute(hook)
          end
        end

        mount ::API::Hooks::Events
      end

      desc 'Add project hook' do
        detail 'Adds a hook to a specified project'
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
          entity: ProjectHook
        }
        mount ::API::Hooks::ResendHook
      end
    end
  end
end

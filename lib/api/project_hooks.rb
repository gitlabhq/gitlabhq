# frozen_string_literal: true

module API
  class ProjectHooks < ::API::Base
    include PaginationParams

    project_hooks_tags = %w[project_hooks]

    before { authenticate! }
    before { authorize_admin_project }

    feature_category :webhooks

    helpers ::API::Helpers::WebHooksHelpers

    helpers do
      def hook_scope
        user_project.hooks
      end

      params :common_hook_parameters do
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
        optional :releases_events, type: Boolean, desc: "Trigger hook on release events"
        optional :emoji_events, type: Boolean, desc: "Trigger hook on emoji events"
        optional :resource_access_token_events, type: Boolean, desc: "Trigger hook on project access token expiry events"
        optional :enable_ssl_verification, type: Boolean, desc: "Do SSL verification when triggering the hook"
        optional :token, type: String, desc: "Secret token to validate received payloads; this will not be returned in the response"
        optional :push_events_branch_filter, type: String, desc: "Trigger hook on specified branch only"
        optional :custom_webhook_template, type: String, desc: "Custom template for the request payload"
        use :url_variables
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      namespace ':id/hooks' do
        mount ::API::Hooks::UrlVariables
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
        present paginate(user_project.hooks), with: Entities::ProjectHook, with_url_variables: false
      end

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
      get ":id/hooks/:hook_id" do
        hook = user_project.hooks.find(params[:hook_id])
        present hook, with: Entities::ProjectHook
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
        hook = user_project.hooks.new(hook_params)

        save_hook(hook, Entities::ProjectHook)
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
      put ":id/hooks/:hook_id" do
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
      delete ":id/hooks/:hook_id" do
        hook = find_hook

        destroy_conditionally!(hook) do
          WebHooks::DestroyService.new(current_user).execute(hook)
        end
      end

      desc 'Triggers a project hook test' do
        detail 'Triggers a project hook test'
        success code: 201
        failure [
          { code: 400, message: 'Bad request' },
          { code: 404, message: 'Not found' },
          { code: 422, message: 'Unprocessable entity' }
        ]
      end
      params do
        requires :trigger,
          type: String,
          desc: 'The type of trigger hook',
          values: ProjectHook.triggers.values.map(&:to_s)
      end
      post ":id/hooks/:hook_id/test/:trigger" do
        hook = find_hook
        result = TestHooks::ProjectService.new(hook, current_user, params[:trigger]).execute
        success = (200..299).cover?(result.payload[:http_status])
        if success
          created!
        else
          render_api_error!(result.message, 422)
        end
      end
    end
  end
end

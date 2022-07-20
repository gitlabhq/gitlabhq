# frozen_string_literal: true

module API
  class ProjectHooks < ::API::Base
    include PaginationParams

    before { authenticate! }
    before { authorize_admin_project }

    feature_category :integrations

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
        optional :enable_ssl_verification, type: Boolean, desc: "Do SSL verification when triggering the hook"
        optional :token, type: String, desc: "Secret token to validate received payloads; this will not be returned in the response"
        optional :push_events_branch_filter, type: String, desc: "Trigger hook on specified branch only"
        use :url_variables
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      namespace ':id/hooks' do
        mount ::API::Hooks::UrlVariables
      end

      desc 'Get project hooks' do
        success Entities::ProjectHook
      end
      params do
        use :pagination
      end
      get ":id/hooks" do
        present paginate(user_project.hooks), with: Entities::ProjectHook
      end

      desc 'Get a project hook' do
        success Entities::ProjectHook
      end
      params do
        requires :hook_id, type: Integer, desc: 'The ID of a project hook'
      end
      get ":id/hooks/:hook_id" do
        hook = user_project.hooks.find(params[:hook_id])
        present hook, with: Entities::ProjectHook
      end

      desc 'Add hook to project' do
        success Entities::ProjectHook
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

      desc 'Update an existing hook' do
        success Entities::ProjectHook
      end
      params do
        requires :hook_id, type: Integer, desc: "The ID of the hook to update"
        use :optional_url
        use :common_hook_parameters
      end
      put ":id/hooks/:hook_id" do
        update_hook(entity: Entities::ProjectHook)
      end

      desc 'Deletes project hook' do
        success Entities::ProjectHook
      end
      params do
        requires :hook_id, type: Integer, desc: 'The ID of the hook to delete'
      end
      delete ":id/hooks/:hook_id" do
        hook = find_hook

        destroy_conditionally!(hook) do
          WebHooks::DestroyService.new(current_user).execute(hook)
        end
      end
    end
  end
end

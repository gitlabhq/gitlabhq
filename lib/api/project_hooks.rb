module API
  # Projects API
  class ProjectHooks < Grape::API
    helpers do
      params :project_hook_properties do
        requires :url, type: String, desc: "The URL to send the request to"
        optional :push_events, type: Boolean, desc: "Trigger hook on push events"
        optional :issues_events, type: Boolean, desc: "Trigger hook on issues events"
        optional :merge_requests_events, type: Boolean, desc: "Trigger hook on merge request events"
        optional :tag_push_events, type: Boolean, desc: "Trigger hook on tag push events"
        optional :note_events, type: Boolean, desc: "Trigger hook on note(comment) events"
        optional :build_events, type: Boolean, desc: "Trigger hook on build events"
        optional :pipeline_events, type: Boolean, desc: "Trigger hook on pipeline events"
        optional :wiki_events, type: Boolean, desc: "Trigger hook on wiki events"
        optional :enable_ssl_verification, type: Boolean, desc: "Do SSL verification when triggering the hook"
        optional :token, type: String, desc: "Secret token to validate received payloads; this will not be returned in the response"
      end
    end

    before { authenticate! }
    before { authorize_admin_project }

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects do
      desc 'Get project hooks' do
        success Entities::ProjectHook
      end
      get ":id/hooks" do
        hooks = paginate user_project.hooks

        present hooks, with: Entities::ProjectHook
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
        use :project_hook_properties
      end
      post ":id/hooks" do
        new_hook_params = declared(params, include_missing: false, include_parent_namespaces: false).to_h
        hook = user_project.hooks.new(new_hook_params)

        if hook.save
          present hook, with: Entities::ProjectHook
        else
          error!("Invalid url given", 422) if hook.errors[:url].present?

          not_found!("Project hook #{hook.errors.messages}")
        end
      end

      desc 'Update an existing project hook' do
        success Entities::ProjectHook
      end
      params do
        requires :hook_id, type: Integer, desc: "The ID of the hook to update"
        use :project_hook_properties
      end
      put ":id/hooks/:hook_id" do
        hook = user_project.hooks.find(params[:hook_id])

        new_params = declared(params, include_missing: false, include_parent_namespaces: false).to_h
        new_params.delete('hook_id')

        if hook.update_attributes(new_params)
          present hook, with: Entities::ProjectHook
        else
          error!("Invalid url given", 422) if hook.errors[:url].present?

          not_found!("Project hook #{hook.errors.messages}")
        end
      end

      desc 'Deletes project hook' do
        success Entities::ProjectHook
      end
      params do
        requires :hook_id, type: Integer, desc: 'The ID of the hook to delete'
      end
      delete ":id/hooks/:hook_id" do
        begin
          present user_project.hooks.destroy(params[:hook_id]), with: Entities::ProjectHook
        rescue
          # ProjectHook can raise Error if hook_id not found
          not_found!("Error deleting hook #{params[:hook_id]}")
        end
      end
    end
  end
end

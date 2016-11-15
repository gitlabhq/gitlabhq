module API
  class Triggers < Grape::API
    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects do
      desc 'Trigger a GitLab project build' do
        success Entities::TriggerRequest
      end
      params do
        requires :ref, type: String, desc: 'The commit sha or name of a branch or tag'
        requires :token, type: String, desc: 'The unique token of trigger'
        optional :variables, type: Hash, desc: 'The list of variables to be injected into build'
      end
      post ":id/(ref/:ref/)trigger/builds" do
        project = Project.find_with_namespace(params[:id]) || Project.find_by(id: params[:id])
        trigger = Ci::Trigger.find_by_token(params[:token].to_s)
        not_found! unless project && trigger
        unauthorized! unless trigger.project == project

        # validate variables
        variables = params[:variables]
        if variables
          unless variables.all? { |key, value| key.is_a?(String) && value.is_a?(String) }
            render_api_error!('variables needs to be a map of key-valued strings', 400)
          end

          # convert variables from Mash to Hash
          variables = variables.to_h
        end

        # create request and trigger builds
        trigger_request = Ci::CreateTriggerRequestService.new.execute(project, trigger, params[:ref].to_s, variables)
        if trigger_request
          present trigger_request, with: Entities::TriggerRequest
        else
          errors = 'No builds created'
          render_api_error!(errors, 400)
        end
      end

      desc 'Get triggers list' do
        success Entities::Trigger
      end
      get ':id/triggers' do
        authenticate!
        authorize! :admin_build, user_project

        triggers = user_project.triggers.includes(:trigger_requests)

        present paginate(triggers), with: Entities::Trigger
      end

      desc 'Get specific trigger of a project' do
        success Entities::Trigger
      end
      params do
        requires :token, type: String, desc: 'The unique token of trigger'
      end
      get ':id/triggers/:token' do
        authenticate!
        authorize! :admin_build, user_project

        trigger = user_project.triggers.find_by(token: params[:token].to_s)
        return not_found!('Trigger') unless trigger

        present trigger, with: Entities::Trigger
      end

      desc 'Create a trigger' do
        success Entities::Trigger
      end
      post ':id/triggers' do
        authenticate!
        authorize! :admin_build, user_project

        trigger = user_project.triggers.create

        present trigger, with: Entities::Trigger
      end

      desc 'Delete a trigger' do
        success Entities::Trigger
      end
      params do
        requires :token, type: String, desc: 'The unique token of trigger'
      end
      delete ':id/triggers/:token' do
        authenticate!
        authorize! :admin_build, user_project

        trigger = user_project.triggers.find_by(token: params[:token].to_s)
        return not_found!('Trigger') unless trigger

        trigger.destroy

        present trigger, with: Entities::Trigger
      end
    end
  end
end

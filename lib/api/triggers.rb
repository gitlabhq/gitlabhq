module API
  # Triggers API
  class Triggers < Grape::API
    resource :projects do
      desc 'Trigger a GitLab project build' do
        success Entities::TriggerRequest
      end
      params do
        requires :id, type: Integer, desc: 'The ID of a CI project'
        requires :ref, type: String, desc: "The name of project's branch or tag"
        requires :token, type: String, desc: 'The unique token of the trigger'
        optional :variables, type: Hash, desc: 'The list of variables to be injected into build' do
          requires :key, type: String
          requires :value, type: String
        end
      end
      post ":id/trigger/builds" do
        project = Project.find_with_namespace(params[:id]) || Project.find_by(id: params[:id])
        trigger = Ci::Trigger.find_by_token(params[:token].to_s)
        not_found! unless project && trigger
        unauthorized! unless trigger.project == project

        # validate variables
        variables = params[:variables]
        if variables
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
      params do
        requires :id, type: Integer, desc: 'The ID of a project'
        optional :page, type: Integer, desc: 'The page number for pagination'
        optional :per_page, type: Integer, desc: 'The value of items per page to show'
      end
      get ':id/triggers' do
        authenticate!
        authorize! :admin_build, user_project

        triggers = user_project.triggers.includes(:trigger_requests)
        triggers = paginate(triggers)

        present triggers, with: Entities::Trigger
      end

      desc 'Get specific trigger of a project' do
        success Entities::Trigger
      end
      params do
        requires :id, type: Integer, desc: 'The ID of a project'
        requires :token, type: String, desc: 'The token of a trigger'
      end
      get ':id/triggers/:token' do
        authenticate!
        authorize! :admin_build, user_project

        trigger = user_project.triggers.find_by(token: params[:token].to_s)
        return not_found!('Trigger') unless trigger

        present trigger, with: Entities::Trigger
      end

      desc 'Create trigger' do
        success Entities::Trigger
      end
      params do
        requires :id, type: Integer, desc: 'The ID of a project'
      end
      post ':id/triggers' do
        authenticate!
        authorize! :admin_build, user_project

        trigger = user_project.triggers.create

        present trigger, with: Entities::Trigger
      end

      desc 'Delete trigger' do
        success Entities::Trigger
      end
      params do
        requires :id, type: Integer, desc: 'The ID of a project'
        requires :token, type: String, desc: 'The token of a trigger'
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

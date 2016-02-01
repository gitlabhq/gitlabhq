module API
  # Triggers API
  class Triggers < Grape::API
    resource :projects do
      # Trigger a GitLab project build
      #
      # Parameters:
      #   id (required) - The ID of a CI project
      #   ref (required) - The name of project's branch or tag
      #   token (required) - The uniq token of trigger
      #   variables (optional) - The list of variables to be injected into build
      # Example Request:
      #   POST /projects/:id/trigger/builds
      post ":id/trigger/builds" do
        required_attributes! [:ref, :token]

        project = Project.find_with_namespace(params[:id]) || Project.find_by(id: params[:id])
        trigger = Ci::Trigger.find_by_token(params[:token].to_s)
        not_found! unless project && trigger
        unauthorized! unless trigger.project == project

        # validate variables
        variables = params[:variables]
        if variables
          unless variables.is_a?(Hash)
            render_api_error!('variables needs to be a hash', 400)
          end

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

      # Get triggers list
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   page (optional) - The page number for pagination
      #   per_page (optional) - The value of items per page to show
      # Example Request:
      #   GET /projects/:id/triggers
      get ':id/triggers' do
        authenticate!
        authorize! :admin_build, user_project

        triggers = user_project.triggers.includes(:trigger_requests)
        triggers = paginate(triggers)

        present triggers, with: Entities::Trigger
      end

      # Get specific trigger of a project
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   token (required) - The `token` of a trigger
      # Example Request:
      #   GET /projects/:id/triggers/:token
      get ':id/triggers/:token' do
        authenticate!
        authorize! :admin_build, user_project

        trigger = user_project.triggers.find_by(token: params[:token].to_s)
        return not_found!('Trigger') unless trigger

        present trigger, with: Entities::Trigger
      end

      # Create trigger
      #
      # Parameters:
      #   id (required) - The ID of a project
      # Example Request:
      #   POST /projects/:id/triggers
      post ':id/triggers' do
        authenticate!
        authorize! :admin_build, user_project

        trigger = user_project.triggers.create

        present trigger, with: Entities::Trigger
      end

      # Delete trigger
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   token (required) - The `token` of a trigger
      # Example Request:
      #   DELETE /projects/:id/triggers/:token
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

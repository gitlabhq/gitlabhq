module Ci
  module API
    # Build Trigger API
    class Triggers < Grape::API
      resource :projects do
        # Trigger a GitLab CI project build
        #
        # Parameters:
        #   id (required) - The ID of a CI project
        #   ref (required) - The name of project's branch or tag
        #   token (required) - The uniq token of trigger
        # Example Request:
        #   POST /projects/:id/ref/:ref/trigger
        post ":id/refs/:ref/trigger" do
          required_attributes! [:token]

          project = Project.find_by(ci_id: params[:id].to_i)
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
      end
    end
  end
end

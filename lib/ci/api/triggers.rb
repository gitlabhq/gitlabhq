module Ci
  module API
    class Triggers < Grape::API
      resource :projects do
        desc 'Trigger a GitLab CI project build' do
          success Entities::TriggerRequest
        end
        params do
          requires :id, type: Integer, desc: 'The ID of a CI project'
          requires :ref, type: String, desc: "The name of project's branch or tag"
          requires :token, type: String, desc: 'The unique token of the trigger'
          optional :variables, type: Hash, desc: 'Optional build variables'
        end
        post ":id/refs/:ref/trigger" do
          project = Project.find_by(ci_id: params[:id])
          trigger = Ci::Trigger.find_by_token(params[:token])
          not_found! unless project && trigger
          unauthorized! unless trigger.project == project

          # Validate variables
          variables = params[:variables].to_h
          unless variables.all? { |key, value| key.is_a?(String) && value.is_a?(String) }
            render_api_error!('variables needs to be a map of key-valued strings', 400)
          end

          # create request and trigger builds
          result = Ci::CreateTriggerRequestService.execute(project, trigger, params[:ref], variables)
          pipeline = result.pipeline

          if pipeline.persisted?
            present result.trigger_request, with: Entities::TriggerRequest
          else
            render_validation_error!(pipeline)
          end
        end
      end
    end
  end
end

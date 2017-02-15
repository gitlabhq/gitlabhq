module API
  module V3
    class Triggers < Grape::API
      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource :projects do
        desc 'Trigger a GitLab project build' do
          success V3::Entities::TriggerRequest
        end
        params do
          requires :ref, type: String, desc: 'The commit sha or name of a branch or tag'
          requires :token, type: String, desc: 'The unique token of trigger'
          optional :variables, type: Hash, desc: 'The list of variables to be injected into build'
        end
        post ":id/(ref/:ref/)trigger/builds" do
          project = find_project(params[:id])
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
      end
    end
  end
end

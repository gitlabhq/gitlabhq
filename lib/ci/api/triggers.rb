module Ci
  module API
    # Build Trigger API
    class Triggers < Grape::API
      resource :projects do
        desc 'Trigger a GitLab CI project build'
        params do
          requires :ref, type: String, desc: 'The commit sha or name of a branch or tag'
          requires :token, type: String, desc: 'The unique token of trigger'
          optional :variables, type: Hash, desc: 'The list of variables to be injected into build'
        end
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
          pipeline = Ci::CreatePipelineService.new(project, nil, ref: params[:ref].to_s).
            execute(ignore_skip_ci: true, trigger: trigger, trigger_variables: variables)
          if pipeline
            data = { id: pipeline.trigger_id, variables: pipeline.trigger_variables }
            present data
          else
            errors = 'No builds created'
            render_api_error!(errors, 400)
          end
        end
      end
    end
  end
end

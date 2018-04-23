module API
  module V3
    class Triggers < Grape::API
      include PaginationParams

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource :projects, requirements: { id: %r{[^/]+} } do
        desc 'Trigger a GitLab project build' do
          success ::API::V3::Entities::TriggerRequest
        end
        params do
          requires :ref, type: String, desc: 'The commit sha or name of a branch or tag'
          requires :token, type: String, desc: 'The unique token of trigger'
          optional :variables, type: Hash, desc: 'The list of variables to be injected into build'
        end
        post ":id/(ref/:ref/)trigger/builds", requirements: { ref: /.+/ } do
          Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-ce/issues/42121')

          # validate variables
          params[:variables] = params[:variables].to_h
          unless params[:variables].all? { |key, value| key.is_a?(String) && value.is_a?(String) }
            render_api_error!('variables needs to be a map of key-valued strings', 400)
          end

          project = find_project(params[:id])
          not_found! unless project

          result = Ci::PipelineTriggerService.new(project, nil, params).execute
          not_found! unless result

          if result[:http_status]
            render_api_error!(result[:message], result[:http_status])
          else
            pipeline = result[:pipeline]

            # We switched to Ci::PipelineVariable from Ci::TriggerRequest.variables.
            # Ci::TriggerRequest doesn't save variables anymore.
            # Here is copying Ci::PipelineVariable to Ci::TriggerRequest.variables for presenting the variables.
            # The same endpoint in v4 API pressents Pipeline instead of TriggerRequest, so it doesn't need such a process.
            trigger_request = pipeline.trigger_requests.last
            trigger_request.variables = params[:variables]

            present trigger_request, with: ::API::V3::Entities::TriggerRequest
          end
        end

        desc 'Get triggers list' do
          success ::API::V3::Entities::Trigger
        end
        params do
          use :pagination
        end
        get ':id/triggers' do
          authenticate!
          authorize! :admin_build, user_project

          triggers = user_project.triggers.includes(:trigger_requests)

          present paginate(triggers), with: ::API::V3::Entities::Trigger
        end

        desc 'Get specific trigger of a project' do
          success ::API::V3::Entities::Trigger
        end
        params do
          requires :token, type: String, desc: 'The unique token of trigger'
        end
        get ':id/triggers/:token' do
          authenticate!
          authorize! :admin_build, user_project

          trigger = user_project.triggers.find_by(token: params[:token].to_s)
          break not_found!('Trigger') unless trigger

          present trigger, with: ::API::V3::Entities::Trigger
        end

        desc 'Create a trigger' do
          success ::API::V3::Entities::Trigger
        end
        post ':id/triggers' do
          authenticate!
          authorize! :admin_build, user_project

          trigger = user_project.triggers.create

          present trigger, with: ::API::V3::Entities::Trigger
        end

        desc 'Delete a trigger' do
          success ::API::V3::Entities::Trigger
        end
        params do
          requires :token, type: String, desc: 'The unique token of trigger'
        end
        delete ':id/triggers/:token' do
          authenticate!
          authorize! :admin_build, user_project

          trigger = user_project.triggers.find_by(token: params[:token].to_s)
          break not_found!('Trigger') unless trigger

          trigger.destroy

          present trigger, with: ::API::V3::Entities::Trigger
        end
      end
    end
  end
end

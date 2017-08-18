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
          project = find_project(params[:id])
          trigger = Ci::Trigger.find_by_token(params[:token].to_s)
          not_found! unless project && trigger
          unauthorized! unless trigger.project == project

          # validate variables
          variables = params[:variables].to_h
          unless variables.all? { |key, value| key.is_a?(String) && value.is_a?(String) }
            render_api_error!('variables needs to be a map of key-valued strings', 400)
          end

          # create request and trigger builds
          result = Ci::CreateTriggerRequestService.execute(project, trigger, params[:ref].to_s, variables)
          pipeline = result.pipeline

          if pipeline.persisted?
            present result.trigger_request, with: ::API::V3::Entities::TriggerRequest
          else
            render_validation_error!(pipeline)
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
          return not_found!('Trigger') unless trigger

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
          return not_found!('Trigger') unless trigger

          trigger.destroy

          present trigger, with: ::API::V3::Entities::Trigger
        end
      end
    end
  end
end

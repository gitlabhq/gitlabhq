# frozen_string_literal: true

module API
  module Ci
    class Triggers < ::API::Base
      include PaginationParams

      HTTP_GITLAB_EVENT_HEADER = "HTTP_#{::Gitlab::WebHooks::GITLAB_EVENT_HEADER}".underscore.upcase

      feature_category :pipeline_composition
      urgency :low

      params do
        requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project',
          documentation: { example: 18 }
      end
      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'Trigger a GitLab project pipeline' do
          success code: 201, model: Entities::Ci::Pipeline
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          requires :ref, type: String, desc: 'The commit sha or name of a branch or tag', allow_blank: false,
            documentation: { example: 'develop' }
          requires :token, type: String, desc: 'The unique token of trigger or job token',
            documentation: { example: '6d056f63e50fe6f8c5f8f4aa10edb7' }
          optional :variables, type: Hash, desc: 'The list of variables to be injected into build',
            documentation: { example: { VAR1: "value1", VAR2: "value2" } }
        end
        post ":id/(ref/:ref/)trigger/pipeline", requirements: { ref: /.+/ } do
          Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/20758')

          forbidden! if gitlab_pipeline_hook_request?

          # validate variables
          params[:variables] = params[:variables].to_h
          unless params[:variables].all? { |key, value| key.is_a?(String) && value.is_a?(String) }
            render_api_error!('variables needs to be a map of key-valued strings', 400)
          end

          project = find_project(params[:id])
          not_found! unless project

          result = ::Ci::PipelineTriggerService.new(project, nil, params).execute
          not_found! unless result

          if result.error?
            render_api_error!(result[:message], result[:http_status])
          else
            present result[:pipeline], with: Entities::Ci::Pipeline
          end
        end

        desc 'Get trigger tokens list' do
          success code: 200, model: Entities::Trigger
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          is_array true
        end
        params do
          use :pagination
        end
        # rubocop: disable CodeReuse/ActiveRecord
        get ':id/triggers' do
          authenticate!
          authorize! :admin_build, user_project

          triggers = user_project.triggers.includes(:trigger_requests)

          present paginate(triggers), with: Entities::Trigger, current_user: current_user
        end
        # rubocop: enable CodeReuse/ActiveRecord

        desc 'Get specific trigger token of a project' do
          success code: 200, model: Entities::Trigger
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          requires :trigger_id, type: Integer, desc: 'The trigger token ID', documentation: { example: 10 }
        end
        get ':id/triggers/:trigger_id' do
          authenticate!
          authorize! :admin_build, user_project

          trigger = user_project.triggers.find(params.delete(:trigger_id))
          break not_found!('Trigger') unless trigger

          present trigger, with: Entities::Trigger, current_user: current_user
        end

        desc 'Create a trigger token' do
          success code: 201, model: Entities::Trigger
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          requires :description, type: String, desc: 'The trigger token description',
            documentation: { example: 'my trigger token description' }
          optional :expires_at, type: DateTime, desc: 'Timestamp of when the pipeline trigger token expires.',
            documentation: { example: '2024-07-01' }
        end
        post ':id/triggers' do
          authenticate!
          authorize! :manage_trigger, user_project

          response =
            ::Ci::PipelineTriggers::CreateService.new(
              project: user_project,
              user: current_user,
              description: declared_params(include_missing: false)[:description],
              expires_at: declared_params(include_missing: true)[:expires_at]
            ).execute

          if response.success?
            present response.payload[:trigger], with: Entities::Trigger, current_user: current_user
          elsif response.reason == :forbidden
            forbidden!(response.message)
          else
            bad_request!(response.message)
          end
        end

        desc 'Update a trigger token' do
          success code: 200, model: Entities::Trigger
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          requires :trigger_id, type: Integer,  desc: 'The trigger token ID'
          optional :description, type: String,  desc: 'The trigger token description'
        end
        put ':id/triggers/:trigger_id' do
          authenticate!

          trigger = user_project.triggers.find(params.delete(:trigger_id))
          break not_found!('Trigger') unless trigger

          response =
            ::Ci::PipelineTriggers::UpdateService.new(
              user: current_user,
              trigger: trigger,
              description: declared_params(include_missing: false)[:description]
            ).execute

          if response.success?
            present response.payload[:trigger], with: Entities::Trigger, current_user: current_user
          elsif response.reason == :forbidden
            forbidden!(response.message)
          else
            bad_request!(response.message)
          end
        end

        desc 'Delete a trigger token' do
          success code: 204
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' },
            { code: 412, message: 'Precondition Failed' }
          ]
        end
        params do
          requires :trigger_id, type: Integer, desc: 'The trigger token ID', documentation: { example: 10 }
        end
        delete ':id/triggers/:trigger_id' do
          authenticate!
          authorize! :manage_trigger, user_project

          trigger = user_project.triggers.find(params.delete(:trigger_id))
          break not_found!('Trigger') unless trigger

          destroy_conditionally!(trigger)
        end
      end

      helpers do
        def gitlab_pipeline_hook_request?
          request.get_header(HTTP_GITLAB_EVENT_HEADER) == WebHookService.hook_to_event(:pipeline_hooks)
        end
      end
    end
  end
end

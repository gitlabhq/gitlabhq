# frozen_string_literal: true

module API
  class Triggers < ::API::Base
    include PaginationParams

    HTTP_GITLAB_EVENT_HEADER = "HTTP_#{WebHookService::GITLAB_EVENT_HEADER}".underscore.upcase

    feature_category :continuous_integration

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Trigger a GitLab project pipeline' do
        success Entities::Ci::Pipeline
      end
      params do
        requires :ref, type: String, desc: 'The commit sha or name of a branch or tag', allow_blank: false
        requires :token, type: String, desc: 'The unique token of trigger or job token'
        optional :variables, type: Hash, desc: 'The list of variables to be injected into build'
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

      desc 'Get triggers list' do
        success Entities::Trigger
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

      desc 'Get specific trigger of a project' do
        success Entities::Trigger
      end
      params do
        requires :trigger_id, type: Integer, desc: 'The trigger ID'
      end
      get ':id/triggers/:trigger_id' do
        authenticate!
        authorize! :admin_build, user_project

        trigger = user_project.triggers.find(params.delete(:trigger_id))
        break not_found!('Trigger') unless trigger

        present trigger, with: Entities::Trigger, current_user: current_user
      end

      desc 'Create a trigger' do
        success Entities::Trigger
      end
      params do
        requires :description, type: String, desc: 'The trigger description'
      end
      post ':id/triggers' do
        authenticate!
        authorize! :admin_build, user_project

        trigger = user_project.triggers.create(
          declared_params(include_missing: false).merge(owner: current_user))

        if trigger.valid?
          present trigger, with: Entities::Trigger, current_user: current_user
        else
          render_validation_error!(trigger)
        end
      end

      desc 'Update a trigger' do
        success Entities::Trigger
      end
      params do
        requires :trigger_id, type: Integer,  desc: 'The trigger ID'
        optional :description, type: String,  desc: 'The trigger description'
      end
      put ':id/triggers/:trigger_id' do
        authenticate!
        authorize! :admin_build, user_project

        trigger = user_project.triggers.find(params.delete(:trigger_id))
        break not_found!('Trigger') unless trigger

        authorize! :admin_trigger, trigger

        if trigger.update(declared_params(include_missing: false))
          present trigger, with: Entities::Trigger, current_user: current_user
        else
          render_validation_error!(trigger)
        end
      end

      desc 'Delete a trigger' do
        success Entities::Trigger
      end
      params do
        requires :trigger_id, type: Integer, desc: 'The trigger ID'
      end
      delete ':id/triggers/:trigger_id' do
        authenticate!
        authorize! :admin_build, user_project

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

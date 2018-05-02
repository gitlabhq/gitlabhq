module API
  class Triggers < Grape::API
    include PaginationParams

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS  do
      desc 'Trigger a GitLab project pipeline' do
        success Entities::Pipeline
      end
      params do
        requires :ref, type: String, desc: 'The commit sha or name of a branch or tag'
        requires :token, type: String, desc: 'The unique token of trigger or job token'
        optional :variables, type: Hash, desc: 'The list of variables to be injected into build'
      end
      post ":id/(ref/:ref/)trigger/pipeline", requirements: { ref: /.+/ } do
        Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-ce/issues/42283')

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
          present result[:pipeline], with: Entities::Pipeline
        end
      end

      desc 'Get triggers list' do
        success Entities::Trigger
      end
      params do
        use :pagination
      end
      get ':id/triggers' do
        authenticate!
        authorize! :admin_build, user_project

        triggers = user_project.triggers.includes(:trigger_requests)

        present paginate(triggers), with: Entities::Trigger
      end

      desc 'Get specific trigger of a project' do
        success Entities::Trigger
      end
      params do
        requires :trigger_id, type: Integer,  desc: 'The trigger ID'
      end
      get ':id/triggers/:trigger_id' do
        authenticate!
        authorize! :admin_build, user_project

        trigger = user_project.triggers.find(params.delete(:trigger_id))
        break not_found!('Trigger') unless trigger

        present trigger, with: Entities::Trigger
      end

      desc 'Create a trigger' do
        success Entities::Trigger
      end
      params do
        requires :description, type: String,  desc: 'The trigger description'
      end
      post ':id/triggers' do
        authenticate!
        authorize! :admin_build, user_project

        trigger = user_project.triggers.create(
          declared_params(include_missing: false).merge(owner: current_user))

        if trigger.valid?
          present trigger, with: Entities::Trigger
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

        if trigger.update(declared_params(include_missing: false))
          present trigger, with: Entities::Trigger
        else
          render_validation_error!(trigger)
        end
      end

      desc 'Take ownership of trigger' do
        success Entities::Trigger
      end
      params do
        requires :trigger_id, type: Integer,  desc: 'The trigger ID'
      end
      post ':id/triggers/:trigger_id/take_ownership' do
        authenticate!
        authorize! :admin_build, user_project

        trigger = user_project.triggers.find(params.delete(:trigger_id))
        break not_found!('Trigger') unless trigger

        if trigger.update(owner: current_user)
          status :ok
          present trigger, with: Entities::Trigger
        else
          render_validation_error!(trigger)
        end
      end

      desc 'Delete a trigger' do
        success Entities::Trigger
      end
      params do
        requires :trigger_id, type: Integer,  desc: 'The trigger ID'
      end
      delete ':id/triggers/:trigger_id' do
        authenticate!
        authorize! :admin_build, user_project

        trigger = user_project.triggers.find(params.delete(:trigger_id))
        break not_found!('Trigger') unless trigger

        destroy_conditionally!(trigger)
      end
    end
  end
end

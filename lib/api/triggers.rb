module API
  class Triggers < Grape::API
    include PaginationParams

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: { id: %r{[^/]+} } do
      desc 'Trigger a GitLab project pipeline' do
        success Entities::Pipeline
      end
      params do
        requires :ref, type: String, desc: 'The commit sha or name of a branch or tag'
        requires :token, type: String, desc: 'The unique token of trigger'
        optional :variables, type: Hash, desc: 'The list of variables to be injected into build'
      end
      post ":id/(ref/:ref/)trigger/pipeline", requirements: { ref: /.+/ } do
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
          present pipeline, with: Entities::Pipeline
        else
          render_validation_error!(pipeline)
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
        return not_found!('Trigger') unless trigger

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
        return not_found!('Trigger') unless trigger

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
        return not_found!('Trigger') unless trigger

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
        return not_found!('Trigger') unless trigger

        trigger.destroy
      end
    end
  end
end

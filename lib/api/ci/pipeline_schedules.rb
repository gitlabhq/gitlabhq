# frozen_string_literal: true

module API
  module Ci
    class PipelineSchedules < ::API::Base
      include PaginationParams

      before { authenticate! }

      feature_category :continuous_integration
      urgency :low

      params do
        requires :id, types: [String, Integer], desc: 'ID or URL-encoded path of the project.',
          documentation: { example: 18 }
      end
      resource :projects, requirements: ::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'List all pipeline schedules' do
          detail 'Lists all pipeline schedules for a project.'
          success code: 200, model: Entities::Ci::PipelineSchedule
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          is_array true
          tags %w[pipeline_schedules]
        end
        params do
          use :pagination
          optional :scope, type: String, values: %w[active inactive],
            desc: 'Scope of pipeline schedules.',
            documentation: { example: 'active' }
        end

        # rubocop: disable CodeReuse/ActiveRecord
        route_setting :authorization, permissions: :read_pipeline_schedule, boundary_type: :project
        get ':id/pipeline_schedules' do
          authorize! :read_pipeline_schedule, user_project

          schedules = ::Ci::PipelineSchedulesFinder.new(user_project).execute(scope: params[:scope])
            .preload([:owner, :inputs])
          present paginate(schedules), with: Entities::Ci::PipelineSchedule, user: current_user
        end
        # rubocop: enable CodeReuse/ActiveRecord

        desc 'Retrieve a pipeline schedule' do
          detail 'Retrieves a pipeline schedule for a project.'
          success code: 200, model: Entities::Ci::PipelineScheduleDetails
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags %w[pipeline_schedules]
        end
        params do
          requires :pipeline_schedule_id, type: Integer, desc: 'ID of the pipeline schedule.', documentation: { example: 13 }
        end

        route_setting :authorization, permissions: :read_pipeline_schedule, boundary_type: :project
        get ':id/pipeline_schedules/:pipeline_schedule_id' do
          present pipeline_schedule, with: Entities::Ci::PipelineScheduleDetails, user: current_user
        end

        desc 'List all pipelines triggered by a pipeline schedule' do
          detail 'Lists all pipelines triggered by a pipeline schedule in a project.'
          success code: 200, model: Entities::Ci::PipelineBasic
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          is_array true
          tags %w[pipeline_schedules]
        end
        params do
          use :pagination
          requires :pipeline_schedule_id, type: Integer, desc: 'ID of the pipeline schedule.', documentation: { example: 13 }
          optional :scope, type: String, values: ::Ci::PipelinesFinder::ALLOWED_SCOPES.values,
            desc: 'Return pipelines in the specified scope.',
            documentation: { example: 'pending' }
          optional :status, type: String, values: ::Ci::HasStatus::AVAILABLE_STATUSES,
            desc: 'Return pipelines with the specified status.',
            documentation: { example: 'pending' }
          optional :updated_before, type: DateTime, desc: 'Return pipelines updated on or before the specified time.',
            documentation: { example: '2015-12-24T15:51:21.880Z' }
          optional :updated_after, type: DateTime, desc: 'Return pipelines updated on or after the specified time.',
            documentation: { example: '2015-12-24T15:51:21.880Z' }
          optional :created_before, type: DateTime, desc: 'Return pipelines created before the specified time.',
            documentation: { example: '2015-12-24T15:51:21.880Z' }
          optional :created_after, type: DateTime, desc: 'Return pipelines created after the specified time.',
            documentation: { example: '2015-12-24T15:51:21.880Z' }
          optional :sort, type: String, values: %w[asc desc], default: 'asc',
            desc: 'Sort results in ascending or descending order.',
            documentation: { example: 'desc' }
        end

        route_setting :authorization, permissions: [:read_pipeline_schedule, :read_pipeline], boundary_type: :project
        get ':id/pipeline_schedules/:pipeline_schedule_id/pipelines' do
          pipelines = ::Ci::PipelinesFinder.new(
            pipeline_schedule.project,
            current_user,
            declared_params.except(:pipeline_schedule_id).merge(pipeline_schedules: [pipeline_schedule])
          ).execute

          present paginate(pipelines), with: Entities::Ci::PipelineBasic
        end

        desc 'Create a pipeline schedule' do
          detail 'Creates a pipeline schedule.'
          success code: 201, model: Entities::Ci::PipelineScheduleDetails
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags %w[pipeline_schedules]
        end
        params do
          requires :description, type: String, desc: 'Description of the pipeline schedule.', documentation: { example: 'Test schedule pipeline' }
          requires :ref, type: String, desc: 'Branch or tag name that triggers the pipeline. Accepts either short refs (`main`) or full refs (`refs/heads/main` or `refs/tags/main`). Short refs are automatically expanded to full refs, unless the value could match either a branch or a tag.', allow_blank: false, documentation: { example: 'develop' }
          requires :cron, type: String, desc: 'Cron schedule, for example `0 1 * * *`.', documentation: { example: '* * * * *' }
          optional :cron_timezone, type: String, default: 'UTC', desc: 'Time zone supported by `ActiveSupport::TimeZone`, for example `Pacific Time (US & Canada)`, or `TZInfo::Timezone`, for example `America/Los_Angeles`.', documentation: { example: 'Asia/Tokyo' }
          optional :active, type: Boolean, default: true, desc: 'If `true`, activates the pipeline schedule. If `false`, the pipeline schedule is initially deactivated.', documentation: { example: true }
          optional :inputs, type: Array, desc: 'Array of inputs to pass to the pipeline schedule. Each input has a `name` and a `value`, which can be a string, array, number, or boolean. To delete an existing input, include the `name` field and set `destroy` to `true`.', documentation: { example: [{ name: 'array_input', value: [1, 2] }, { name: 'boolean_input', value: true }] } do
            requires :name, type: String, desc: 'Name of the input.', documentation: { example: 'deploy_strategy' }
            requires :value, types: [String, Array, Numeric, TrueClass, FalseClass], desc: 'Value of the input.', documentation: { example: 'blue-green' }
          end
        end

        route_setting :authorization, permissions: :create_pipeline_schedule, boundary_type: :project
        route_setting :log_safety, { unsafe_nested: [%w[inputs value]] }
        post ':id/pipeline_schedules' do
          authorize! :create_pipeline_schedule, user_project

          schedule_params = declared_params(include_missing: false)
          inputs = schedule_params.delete(:inputs)

          if inputs
            schedule_params[:inputs_attributes] = inputs.map do |input|
              input.slice(:name, :value)
            end
          end

          response = ::Ci::PipelineSchedules::CreateService
            .new(user_project, current_user, schedule_params)
            .execute

          pipeline_schedule = response.payload

          if response.success?
            present pipeline_schedule, with: Entities::Ci::PipelineScheduleDetails
          else
            render_validation_error!(pipeline_schedule)
          end
        end

        desc 'Update a pipeline schedule' do
          detail 'Updates a pipeline schedule for a project. After the update is done, it is rescheduled automatically.'
          success code: 200, model: Entities::Ci::PipelineScheduleDetails
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags %w[pipeline_schedules]
        end
        params do
          requires :pipeline_schedule_id, type: Integer, desc: 'ID of the pipeline schedule.', documentation: { example: 13 }
          optional :description, type: String, desc: 'Description of the pipeline schedule.', documentation: { example: 'Test schedule pipeline' }
          optional :ref, type: String, desc: 'Branch or tag name that triggers the pipeline. Accepts either short refs (`main`) or full refs (`refs/heads/main` or `refs/tags/main`). Short refs are automatically expanded to full refs, unless the value could match either a branch or a tag.', documentation: { example: 'develop' }
          optional :cron, type: String, desc: 'Cron schedule, for example `0 1 * * *`.', documentation: { example: '* * * * *' }
          optional :cron_timezone, type: String, desc: 'Time zone supported by `ActiveSupport::TimeZone`, for example `Pacific Time (US & Canada)`, or `TZInfo::Timezone`, for example `America/Los_Angeles`.', documentation: { example: 'Asia/Tokyo' }
          optional :active, type: Boolean, desc: 'If `true`, activates the pipeline schedule. If `false`, the pipeline schedule is initially deactivated.', documentation: { example: true }
          optional :inputs, type: Array, desc: 'Array of inputs to pass to the pipeline schedule. Each input has a `name` and a `value`, which can be a string, array, number, or boolean. To delete an existing input, include the `name` field and set `destroy` to `true`.', documentation: { example: [{ name: 'deploy_strategy', value: 'blue-green' }] } do
            requires :name, type: String, desc: 'Name of the input.', documentation: { example: 'deploy_strategy' }
            optional :destroy, type: Boolean, desc: 'If `true`, deletes the input.', documentation: { example: false, default: false }
            given destroy: ->(value) { value != true } do
              requires :value, types: [String, Array, Numeric, TrueClass, FalseClass], desc: 'Value of the input.', documentation: { example: 'blue-green' }
            end
          end
        end

        route_setting :authorization, permissions: :update_pipeline_schedule, boundary_type: :project
        route_setting :log_safety, { unsafe_nested: [%w[inputs value]] }
        put ':id/pipeline_schedules/:pipeline_schedule_id' do
          authorize! :update_pipeline_schedule, pipeline_schedule

          schedule_params = declared_params(include_missing: false)
          inputs = schedule_params.delete(:inputs)

          if inputs
            schedule_params[:inputs_attributes] = inputs.map do |input|
              input.slice(:name, :value, :destroy)
            end
          end

          response = ::Ci::PipelineSchedules::UpdateService
            .new(pipeline_schedule, current_user, schedule_params)
            .execute

          if response.success?
            present pipeline_schedule, with: Entities::Ci::PipelineScheduleDetails
          else
            render_validation_error!(pipeline_schedule)
          end
        end

        desc 'Create or update ownership of a pipeline schedule' do
          detail 'Creates or updates the owner of a pipeline schedule for a project.'
          success code: 201, model: Entities::Ci::PipelineScheduleDetails
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags %w[pipeline_schedules]
        end
        params do
          requires :pipeline_schedule_id, type: Integer, desc: 'ID of the pipeline schedule.', documentation: { example: 13 }
        end

        route_setting :authorization, permissions: :own_pipeline_schedule, boundary_type: :project
        post ':id/pipeline_schedules/:pipeline_schedule_id/take_ownership' do
          authorize! :admin_pipeline_schedule, pipeline_schedule

          if pipeline_schedule.owned_by?(current_user)
            status(:ok) # Set response code to 200 if schedule is already owned by current user
            present pipeline_schedule, with: Entities::Ci::PipelineScheduleDetails
          elsif pipeline_schedule.own!(current_user)
            present pipeline_schedule, with: Entities::Ci::PipelineScheduleDetails
          else
            render_validation_error!(pipeline_schedule)
          end
        end

        desc 'Delete a pipeline schedule' do
          detail 'Deletes a pipeline schedule for a project.'
          success code: 204
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' },
            { code: 412, message: 'Precondition Failed' }
          ]
          tags %w[pipeline_schedules]
        end
        params do
          requires :pipeline_schedule_id, type: Integer, desc: 'ID of the pipeline schedule.', documentation: { example: 13 }
        end

        route_setting :authorization, permissions: :delete_pipeline_schedule, boundary_type: :project
        delete ':id/pipeline_schedules/:pipeline_schedule_id' do
          authorize! :admin_pipeline_schedule, pipeline_schedule

          destroy_conditionally!(pipeline_schedule)
        end

        desc 'Run a pipeline schedule' do
          detail 'Runs a pipeline schedule immediately. The next scheduled run of this pipeline is not affected.'
          success code: 201
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags %w[pipeline_schedules]
        end
        params do
          requires :pipeline_schedule_id, type: Integer, desc: 'ID of the pipeline schedule.', documentation: { example: 13 }
        end

        route_setting :authorization, permissions: :play_pipeline_schedule, boundary_type: :project
        post ':id/pipeline_schedules/:pipeline_schedule_id/play' do
          authorize! :play_pipeline_schedule, pipeline_schedule

          job_id = ::Ci::PipelineSchedules::PlayService
          .new(pipeline_schedule.project, current_user)
          .execute(pipeline_schedule)

          if job_id
            created!
          else
            render_api_error!('Unable to schedule pipeline run immediately', 500)
          end
        end

        desc 'Create a variable for a pipeline schedule' do
          detail 'Creates a variable for a pipeline schedule.'
          success code: 201, model: Entities::Ci::Variable
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags %w[pipeline_schedules]
        end
        params do
          requires :pipeline_schedule_id, type: Integer, desc: 'ID of the pipeline schedule.', documentation: { example: 13 }
          requires :key, type: String, desc: 'Key of the pipeline schedule variable. Must be 255 characters or fewer and contain only `A-Z`, `a-z`, `0-9`, and `_`.', documentation: { example: 'NEW_VARIABLE' }
          requires :value, type: String, desc: 'Value of the variable.', documentation: { example: 'new value' }
          optional :variable_type, type: String, values: ::Ci::PipelineScheduleVariable.variable_types.keys, desc: 'Type of the variable. Defaults to `env_var`.',
            documentation: { default: 'env_var' }
        end

        route_setting :authorization, permissions: :create_pipeline_schedule_variable, boundary_type: :project
        route_setting :log_safety, { safe: %w[key], unsafe: %w[value] }
        post ':id/pipeline_schedules/:pipeline_schedule_id/variables' do
          authorize! :set_pipeline_variables, user_project
          authorize! :update_pipeline_schedule, pipeline_schedule

          response = ::Ci::PipelineSchedules::VariablesCreateService
            .new(pipeline_schedule, current_user, declared_params(include_missing: false))
            .execute

          variable = response.payload

          if response.success?
            present variable, with: Entities::Ci::Variable
          else
            render_validation_error!(variable)
          end
        end

        desc 'Retrieve a variable for a pipeline schedule' do
          detail 'Retrieves a specified variable for a pipeline schedule.'
          success code: 200, model: Entities::Ci::Variable
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags %w[pipeline_schedules]
        end
        params do
          requires :pipeline_schedule_id, type: Integer, desc: 'ID of the pipeline schedule.', documentation: { example: 13 }
          requires :key, type: String, desc: 'Key of the pipeline schedule variable. Must be 255 characters or fewer and contain only `A-Z`, `a-z`, `0-9`, and `_`.', documentation: { example: 'NEW_VARIABLE' }
        end

        route_setting :authorization, permissions: :read_pipeline_schedule_variable, boundary_type: :project
        get ':id/pipeline_schedules/:pipeline_schedule_id/variables/:key' do
          authorize! :read_pipeline_schedule_variables, pipeline_schedule

          present pipeline_schedule_variable, with: Entities::Ci::Variable
        end

        desc 'Update a variable for a pipeline schedule' do
          detail 'Updates a variable for a pipeline schedule.'
          success code: 200, model: Entities::Ci::Variable
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags %w[pipeline_schedules]
        end
        params do
          requires :pipeline_schedule_id, type: Integer, desc: 'ID of the pipeline schedule.', documentation: { example: 13 }
          requires :key, type: String, desc: 'Key of the pipeline schedule variable. Must be 255 characters or fewer and contain only `A-Z`, `a-z`, `0-9`, and `_`.', documentation: { example: 'NEW_VARIABLE' }
          optional :value, type: String, desc: 'Value of the variable.', documentation: { example: 'new value' }
          optional :variable_type, type: String, values: ::Ci::PipelineScheduleVariable.variable_types.keys, desc: 'Type of the variable. Defaults to `env_var`.',
            documentation: { default: 'env_var' }
        end

        route_setting :authorization, permissions: :update_pipeline_schedule_variable, boundary_type: :project
        route_setting :log_safety, { safe: [], unsafe: %w[value] }
        put ':id/pipeline_schedules/:pipeline_schedule_id/variables/:key' do
          authorize! :set_pipeline_variables, user_project
          authorize! :update_pipeline_schedule, pipeline_schedule

          response = ::Ci::PipelineSchedules::VariablesUpdateService
            .new(pipeline_schedule_variable, current_user, declared_params(include_missing: false))
            .execute

          if response.success?
            present pipeline_schedule_variable, with: Entities::Ci::Variable
          else
            render_validation_error!(pipeline_schedule_variable)
          end
        end

        desc 'Delete a variable for a pipeline schedule' do
          detail 'Deletes a specified variable for a pipeline schedule.'
          success code: 202, model: Entities::Ci::Variable
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags %w[pipeline_schedules]
        end
        params do
          requires :pipeline_schedule_id, type: Integer, desc: 'ID of the pipeline schedule.', documentation: { example: 13 }
          requires :key, type: String, desc: 'Key of the pipeline schedule variable. Must be 255 characters or fewer and contain only `A-Z`, `a-z`, `0-9`, and `_`.', documentation: { example: 'NEW_VARIABLE' }
        end

        route_setting :authorization, permissions: :delete_pipeline_schedule_variable, boundary_type: :project
        delete ':id/pipeline_schedules/:pipeline_schedule_id/variables/:key' do
          authorize! :set_pipeline_variables, user_project
          authorize! :admin_pipeline_schedule, pipeline_schedule

          status :accepted
          present pipeline_schedule_variable.destroy, with: Entities::Ci::Variable
        end
      end

      helpers do
        # rubocop: disable CodeReuse/ActiveRecord
        def pipeline_schedule
          @pipeline_schedule ||=
            user_project
              .pipeline_schedules
              .preload(:owner)
              .find_by(id: params.delete(:pipeline_schedule_id)).tap do |pipeline_schedule|
                unless can?(current_user, :read_pipeline_schedule, pipeline_schedule)
                  not_found!('Pipeline Schedule')
                end
              end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        # rubocop: disable CodeReuse/ActiveRecord
        def pipeline_schedule_variable
          @pipeline_schedule_variable ||=
            pipeline_schedule.variables.find_by(key: params[:key]).tap do |pipeline_schedule_variable|
              unless pipeline_schedule_variable
                not_found!('Pipeline Schedule Variable')
              end
            end
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end

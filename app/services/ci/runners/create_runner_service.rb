# frozen_string_literal: true

module Ci
  module Runners
    class CreateRunnerService
      include Gitlab::InternalEventsTracking

      RUNNER_CLASS_MAPPING = {
        'instance_type' => Ci::Runners::RunnerCreationStrategies::InstanceRunnerStrategy,
        'group_type' => Ci::Runners::RunnerCreationStrategies::GroupRunnerStrategy,
        'project_type' => Ci::Runners::RunnerCreationStrategies::ProjectRunnerStrategy
      }.freeze

      def initialize(user:, params:)
        @user = user
        @scope = params[:scope]
        @params = params
        @strategy = RUNNER_CLASS_MAPPING[params[:runner_type]].new(user: user, params: params)
      end

      def execute
        normalize_params

        error = strategy.validate_params
        return ServiceResponse.error(message: error, reason: :validation_error) if error

        unless strategy.authorized_user?
          return ServiceResponse.error(message: _('Insufficient permissions'), reason: :forbidden)
        end

        runner = ::Ci::Runner.new(params)

        if runner.save
          track_runner_events(runner)

          return ServiceResponse.success(payload: { runner: runner })
        end

        ServiceResponse.error(message: runner.errors.full_messages, reason: :save_error)
      end

      def normalize_params
        params[:registration_type] = :authenticated_user
        params[:active] = !params.delete(:paused) if params.key?(:paused)
        params[:creator] = user

        strategy.normalize_params
      end

      private

      attr_reader :user, :scope, :params, :strategy

      def track_runner_events(runner)
        kwargs = { user: user }

        case runner.runner_type
        when 'group_type'
          kwargs[:namespace] = @scope
        when 'project_type'
          kwargs[:project] = @scope
        end

        track_internal_event(
          'create_ci_runner',
          **kwargs,
          additional_properties: {
            label: runner.runner_type,
            property: 'authenticated_user'
          }
        )

        return if params[:maintenance_note].blank?

        track_internal_event(
          'set_runner_maintenance_note',
          **kwargs,
          additional_properties: {
            label: runner.runner_type
          }
        )
      end
    end
  end
end

Ci::Runners::CreateRunnerService.prepend_mod

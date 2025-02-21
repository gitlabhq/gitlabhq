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

        should_mark_hosted = params.delete(:hosted_runner)
        runner = ::Ci::Runner.new(params)

        create_runner(runner, should_mark_hosted)
      end

      def normalize_params
        params[:registration_type] = :authenticated_user
        params[:active] = !params.delete(:paused) if params.key?(:paused)
        params[:creator] = user

        strategy.normalize_params
      end

      private

      attr_reader :user, :scope, :params, :strategy

      def create_runner(runner, should_mark_hosted)
        ApplicationRecord.transaction do
          runner.save!
          create_hosted_runner!(runner, should_mark_hosted)
        end

        track_runner_events(runner)

        ServiceResponse.success(payload: { runner: runner })
      rescue ActiveRecord::RecordInvalid => e
        ServiceResponse.error(message: e.record.errors.full_messages, reason: :save_error)
      end

      # CE implementation - no-op
      def create_hosted_runner!(runner, should_mark_hosted); end

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

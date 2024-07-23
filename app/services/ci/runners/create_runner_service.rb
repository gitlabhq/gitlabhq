# frozen_string_literal: true

module Ci
  module Runners
    class CreateRunnerService
      RUNNER_CLASS_MAPPING = {
        'instance_type' => Ci::Runners::RunnerCreationStrategies::InstanceRunnerStrategy,
        'group_type' => Ci::Runners::RunnerCreationStrategies::GroupRunnerStrategy,
        'project_type' => Ci::Runners::RunnerCreationStrategies::ProjectRunnerStrategy
      }.freeze

      def initialize(user:, params:)
        @user = user
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

        if Namespace.with_disabled_organization_validation { runner.save }
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

      attr_reader :user, :params, :strategy
    end
  end
end

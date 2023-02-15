# frozen_string_literal: true

module Ci
  module Runners
    class CreateRunnerService
      RUNNER_CLASS_MAPPING = {
        'instance_type' => Ci::Runners::RunnerCreationStrategies::InstanceRunnerStrategy,
        nil => Ci::Runners::RunnerCreationStrategies::InstanceRunnerStrategy
      }.freeze

      attr_accessor :user, :type, :params, :strategy

      def initialize(user:, type:, params:)
        @user = user
        @type = type
        @params = params
        @strategy = RUNNER_CLASS_MAPPING[type].new(user: user, type: type, params: params)
      end

      def execute
        normalize_params

        return ServiceResponse.error(message: 'Validation error') unless strategy.validate_params
        return ServiceResponse.error(message: 'Insufficient permissions') unless strategy.authorized_user?

        runner = ::Ci::Runner.new(params)

        return ServiceResponse.success(payload: { runner: runner }) if runner.save

        ServiceResponse.error(message: runner.errors.full_messages)
      end

      def normalize_params
        params[:registration_type] = :authenticated_user
        params[:runner_type] = type
        params[:active] = !params.delete(:paused) if params[:paused].present?
        params[:creator] = user

        strategy.normalize_params
      end
    end
  end
end

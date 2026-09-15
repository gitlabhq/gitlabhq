# frozen_string_literal: true

module Ci
  module RuntimeEnvironments
    class RecordSuccessfulSuspensionService
      def initialize(build, environment_key:)
        @build = build
        @environment_key = environment_key
      end

      def execute
        return if environment_key.blank?
        return unless feature_enabled?

        build_runtime_environment = job_runtime_environment
        return unless build_runtime_environment&.suspend_on_success?

        begin
          runtime_environment = Ci::RuntimeEnvironment.find_or_create_by_key_and_project!(
            environment_key, project_id)
          return if already_linked?(build_runtime_environment, runtime_environment)

          build_runtime_environment.update!(runtime_environment_id: runtime_environment.id)
        rescue StandardError => e
          ::Gitlab::ErrorTracking.track_exception(e, build_id: build.id)
        end
      end

      private

      delegate :job_runtime_environment, :project, :project_id, to: :build

      attr_reader :build, :environment_key

      def feature_enabled?
        ::Feature.enabled?(:ci_suspendable_environment_runner_routing, project,
          type: :gitlab_com_derisk)
      end

      def already_linked?(build_runtime_environment, runtime_environment)
        build_runtime_environment.runtime_environment_id == runtime_environment.id
      end
    end
  end
end

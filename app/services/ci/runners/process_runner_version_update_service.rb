# frozen_string_literal: true

module Ci
  module Runners
    class ProcessRunnerVersionUpdateService
      def initialize(version)
        @version = version
      end

      def execute
        return ServiceResponse.error(message: 'version update disabled') unless enabled?
        return ServiceResponse.error(message: 'version not present') unless @version

        _, status = upgrade_check_service.check_runner_upgrade_suggestion(@version)
        return ServiceResponse.error(message: 'upgrade version check failed') if status == :error

        Ci::RunnerVersion.upsert({ version: @version, status: status })
        ServiceResponse.success(payload: { upgrade_status: status.to_s })
      end

      private

      def upgrade_check_service
        @runner_upgrade_check ||= Gitlab::Ci::RunnerUpgradeCheck.new(::Gitlab::VERSION)
      end

      def enabled?
        Gitlab::Ci::RunnerReleases.instance.enabled?
      end
    end
  end
end

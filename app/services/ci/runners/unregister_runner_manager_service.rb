# frozen_string_literal: true

module Ci
  module Runners
    class UnregisterRunnerManagerService
      attr_reader :runner, :author, :system_id

      # @param [Ci::Runner] runner the runner to unregister/destroy
      # @param [User, authentication token String] author the user or the authentication token authorizing the removal
      # @param [String] system_id ID of the system being unregistered
      def initialize(runner, author, system_id:)
        @runner = runner
        @author = author
        @system_id = system_id
      end

      def execute
        return system_id_missing_error if system_id.blank?

        runner_manager = runner.runner_managers.find_by_system_xid!(system_id)
        runner_manager.destroy!

        runner.clear_heartbeat if runner.runner_managers.empty?

        ServiceResponse.success
      end

      private

      def system_id_missing_error
        ServiceResponse.error(message: '`system_id` needs to be specified.')
      end
    end
  end
end

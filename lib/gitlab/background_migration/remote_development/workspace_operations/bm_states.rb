# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module RemoteDevelopment
      module WorkspaceOperations
        module BmStates
          CREATION_REQUESTED = 'CreationRequested'
          STARTING = 'Starting'
          RESTART_REQUESTED = 'RestartRequested'
          RUNNING = 'Running'
          STOPPING = 'Stopping'
          STOPPED = 'Stopped'
          TERMINATING = 'Terminating'
          TERMINATED = 'Terminated'
          FAILED = 'Failed'
          ERROR = 'Error'
          UNKNOWN = 'Unknown'

          VALID_DESIRED_STATES = [
            RUNNING,
            RESTART_REQUESTED,
            STOPPED,
            TERMINATED
          ].freeze

          VALID_ACTUAL_STATES = [
            CREATION_REQUESTED,
            STARTING,
            RUNNING,
            STOPPING,
            STOPPED,
            TERMINATING,
            TERMINATED,
            FAILED,
            ERROR,
            UNKNOWN
          ].freeze

          # @param [String] state
          # @return [TrueClass, FalseClass]
          def valid_desired_state?(state)
            VALID_DESIRED_STATES.include?(state)
          end

          # @param [String] state
          # @return [TrueClass, FalseClass]
          def valid_actual_state?(state)
            VALID_ACTUAL_STATES.include?(state)
          end
        end
      end
    end
  end
end

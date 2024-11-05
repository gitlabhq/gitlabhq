# frozen_string_literal: true

module Ci
  module Runners
    class UpdateRunnerService
      include Gitlab::InternalEventsTracking

      attr_reader :current_user, :runner

      def initialize(current_user, runner)
        @current_user = current_user
        @runner = runner
      end

      def execute(params)
        params[:active] = !params.delete(:paused) if params.include?(:paused)

        if runner.update(params)
          track_runner_event(params)
          runner.tick_runner_queue

          ServiceResponse.success
        else
          ServiceResponse.error(message: runner.errors.full_messages)
        end
      end

      private

      def track_runner_event(params)
        return if params[:maintenance_note].blank?

        kwargs = { user: current_user }
        case runner.runner_type
        when 'group_type'
          kwargs[:namespace] = runner.owner
        when 'project_type'
          kwargs[:project] = runner.owner
        end

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

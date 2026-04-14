# frozen_string_literal: true

module Gitlab
  module Checks
    class ChangesAccessLogger
      include ::Gitlab::Utils::StrongMemoize

      def self.current_monotonic_time
        ::Gitlab::Metrics::System.monotonic_time
      end

      def initialize(project:, destination: ::Gitlab::AppJsonLogger)
        @project = project
        @destination = destination
        @durations = {}
      end

      def instrument(check_name)
        return yield unless enabled?

        op_started_at = current_monotonic_time

        result = yield

        @durations[check_name] = (@durations[check_name] || 0) + (current_monotonic_time - op_started_at)

        result
      end

      def commit(status:, error: nil)
        return unless enabled?

        durations_array = @durations.map do |name, duration|
          {
            name: name,
            duration_s: duration.round(Gitlab::InstrumentationHelper::DURATION_PRECISION)
          }
        end

        attributes = {
          class: self.class.name,
          project_id: @project.id,
          status: status.to_s,
          changes_access_check_durations: durations_array
        }

        attributes[:error] = error if error
        attributes.compact!
        attributes.stringify_keys!

        @destination.info(attributes)
      end

      private

      delegate :current_monotonic_time, to: :class

      def enabled?
        ::Feature.enabled?(:changes_access_logging, @project, type: :ops)
      end
      strong_memoize_attr :enabled?
    end
  end
end

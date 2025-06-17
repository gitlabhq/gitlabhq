# frozen_string_literal: true

module Gitlab
  module Scheduling
    module TaskExecutor
      def execute_config_task(task_name, config)
        execute_every(config[:period]) do
          unless config[:execute] || config[:dispatch]
            raise NotImplementedError, "No execute block or dispatch defined for task #{task_name}"
          end

          break false if config[:if]&.call == false

          instance_exec(&config[:execute]) if config[:execute]

          dispatch_event(config[:dispatch]) if config[:dispatch]
        end
      end

      def execute_every(period, &block)
        key = cache_key_for_period(period)
        Gitlab::Utils::RedisThrottle.execute_every(period, key, &block)
      end

      def cache_key
        cache_key_for_period(cache_period)
      end

      def cache_period
        nil
      end

      def cache_key_for_period(period)
        [
          self.class.name.underscore,
          :execute_every,
          period.presence || "-",
          task
        ].join(':')
      end

      def dispatch_event(dispatch_config)
        return unless dispatch_config

        event = dispatch_config[:event]
        data_proc = dispatch_config[:data]
        data = data_proc ? data_proc.call : {}

        Gitlab::EventStore.publish(event.new(data: data))
      end
    end
  end
end

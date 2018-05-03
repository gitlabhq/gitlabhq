module Gitlab
  module Geo
    module LogCursor
      class Logger
        attr_accessor :klass

        PID = Process.pid.freeze

        def initialize(klass, level = nil)
          @klass = klass
          geo_logger.build.level = level unless level.nil?
        end

        def event_info(created_at, message, params = {})
          params = params.merge(cursor_delay_s: cursor_delay(created_at))

          info(message, params)
        end

        def info(message, params = {})
          geo_logger.info(base_log_data(message, params))
        end

        def error(message, params = {})
          geo_logger.error(base_log_data(message, params))
        end

        def debug(message, params = {})
          geo_logger.debug(base_log_data(message, params))
        end

        private

        def geo_logger
          Gitlab::Geo::Logger
        end

        def caller_name
          klass.name
        end

        def cursor_delay(created_at)
          (Time.now - created_at).to_f.round(3)
        end

        def base_log_data(message, params = {})
          {
            pid: PID,
            class: caller_name,
            message: message
          }.merge(params)
        end
      end
    end
  end
end

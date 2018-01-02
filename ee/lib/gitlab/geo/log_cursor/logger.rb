module Gitlab
  module Geo
    module LogCursor
      module Logger
        PID = Process.pid.freeze

        def self.event_info(created_at, message, params = {})
          args = { pid: PID,
                   class: caller_name,
                   message: message,
                   cursor_delay_s: cursor_delay(created_at) }.merge(params)

          geo_logger.info(args)
        end

        def self.info(message, params = {})
          geo_logger.info({ pid: PID, class: caller_name, message: message }.merge(params))
        end

        def self.error(message, params = {})
          geo_logger.error({ pid: PID, class: caller_name, message: message }.merge(params))
        end

        def self.debug(message, params = {})
          geo_logger.debug({ pid: PID, class: caller_name, message: message }.merge(params))
        end

        def self.geo_logger
          Gitlab::Geo::Logger
        end

        def self.caller_name
          caller_locations[1].to_s.rpartition('/').last[/[a-z_]*/]&.classify
        end

        def self.cursor_delay(created_at)
          (Time.now - created_at).to_f.round(3)
        end

        private_class_method :caller_name, :cursor_delay
      end
    end
  end
end

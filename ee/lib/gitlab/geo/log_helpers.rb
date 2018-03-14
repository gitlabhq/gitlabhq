module Gitlab
  module Geo
    module LogHelpers
      def log_info(message, details = {})
        data = base_log_data(message)
        data.merge!(details) if details
        geo_logger.info(data)
      end

      def log_error(message, error = nil, details = {})
        data = base_log_data(message)
        data[:error] = error.to_s if error
        data.merge!(details) if details
        geo_logger.error(data)
      end

      protected

      def base_log_data(message)
        {
          class: self.class.name,
          message: message
        }
      end

      def geo_logger
        Gitlab::Geo::Logger
      end
    end
  end
end

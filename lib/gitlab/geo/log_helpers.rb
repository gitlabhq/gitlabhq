module Gitlab
  module Geo
    module LogHelpers
      def log_info(message, details = {})
        data = base_log_data(message)
        data.merge!(details) if details
        Gitlab::Geo::Logger.info(data)
      end

      def log_error(message, error = nil, details = {})
        data = base_log_data(message)
        data[:error] = error.to_s if error
        data.merge!(details) if details
        Gitlab::Geo::Logger.error(data)
      end

      protected

      def base_log_data(message)
        {
          class: self.class.name,
          message: message
        }
      end
    end
  end
end

module Gitlab
  module Geo
    module ProjectLogHelpers
      def log_info(message)
        data = base_log_data(message)
        Gitlab::Geo::Logger.info(data)
      end

      def log_error(message, error)
        data = base_log_data(message)
        data[:error] = error
        Gitlab::Geo::Logger.error(data)
      end

      private

      def base_log_data(message)
        {
          class: self.class.name,
          project_id: project.id,
          project_path: project.path_with_namespace,
          message: message
        }
      end
    end
  end
end

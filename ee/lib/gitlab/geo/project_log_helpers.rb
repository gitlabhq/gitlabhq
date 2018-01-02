module Gitlab
  module Geo
    module ProjectLogHelpers
      include LogHelpers

      def base_log_data(message)
        {
          class: self.class.name,
          project_id: project.id,
          project_path: project.full_path,
          message: message
        }
      end
    end
  end
end

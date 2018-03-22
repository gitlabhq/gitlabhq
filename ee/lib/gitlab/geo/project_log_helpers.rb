module Gitlab
  module Geo
    module ProjectLogHelpers
      include LogHelpers

      def base_log_data(message)
        {
          class: self.class.name,
          project_id: project.id,
          project_path: project.full_path,
          storage_version: project.storage_version,
          message: message
        }
      end
    end
  end
end

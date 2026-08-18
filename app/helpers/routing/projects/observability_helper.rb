# frozen_string_literal: true

module Routing
  module Projects
    module ObservabilityHelper
      def project_observability_path(project, path, **options)
        if path.to_s.include?('/')
          project_observability_sub_path_path(project, sub_path: path, **options)
        else
          super
        end
      end
    end
  end
end

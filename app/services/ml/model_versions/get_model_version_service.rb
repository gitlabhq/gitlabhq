# frozen_string_literal: true

module Ml
  module ModelVersions
    class GetModelVersionService
      def initialize(project, name, version)
        @project = project
        @name = name
        @version = version
      end

      def execute
        Ml::ModelVersion.by_project_id_name_and_version(
          @project.id,
          @name,
          @version
        )
      end
    end
  end
end

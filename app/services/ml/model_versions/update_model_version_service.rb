# frozen_string_literal: true

module Ml
  module ModelVersions
    class UpdateModelVersionService
      def initialize(project, name, version, description)
        @project = project
        @name = name
        @version = version
        @description = description
      end

      def execute
        model_version = Ml::ModelVersion
                          .by_project_id_name_and_version(@project.id, @name, @version)

        return ServiceResponse.error(message: 'Model not found') unless model_version.present?

        result = model_version.update(description: @description)

        return ServiceResponse.error(message: 'Model update failed') unless result

        ServiceResponse.success(payload: model_version)
      end
    end
  end
end

# frozen_string_literal: true

module Ml
  module ModelVersions
    class DeleteService
      def initialize(project, name, version, user)
        @project = project
        @name = name
        @version = version
        @user = user
      end

      def execute
        model_version = Ml::ModelVersion
                          .by_project_id_name_and_version(@project.id, @name, @version)
        return ServiceResponse.error(message: 'Model not found') unless model_version

        if model_version.package.present?
          result = ::Packages::MarkPackageForDestructionService
                     .new(container: model_version.package, current_user: @user)
                     .execute

          return ServiceResponse.error(message: result.message) unless result.success?
        end

        return ServiceResponse.error(message: 'Could not destroy the model version') unless model_version.destroy

        ServiceResponse.success
      end
    end
  end
end

# frozen_string_literal: true

module Ci
  module Catalog
    class ValidateResourceService
      attr_reader :project

      def initialize(project, ref)
        @project = project
        @ref = ref
        @errors = []
      end

      def execute
        check_project_readme
        check_project_description

        if errors.empty?
          ServiceResponse.success
        else
          ServiceResponse.error(message: errors.join(' , '))
        end
      end

      private

      attr_reader :ref, :errors

      def check_project_description
        return if project.description.present?

        errors << 'Project must have a description'
      end

      def check_project_readme
        return if project_has_readme?

        errors << 'Project must have a README'
      end

      def project_has_readme?
        project.repository.blob_data_at(ref, 'README.md')
      end
    end
  end
end

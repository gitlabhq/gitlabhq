# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      class ValidateService
        MINIMUM_AMOUNT_OF_COMPONENTS = 1

        def initialize(project, ref)
          @project = project
          @ref = ref
          @errors = []
        end

        def execute
          verify_presence_project_readme
          verify_presence_project_description
          scan_directory_for_components

          if errors.empty?
            ServiceResponse.success
          else
            ServiceResponse.error(message: errors.join(', '))
          end
        end

        private

        attr_reader :project, :ref, :errors

        def verify_presence_project_readme
          return if project_has_readme?

          errors << 'Project must have a README'
        end

        def verify_presence_project_description
          return if project.description.present?

          errors << 'Project must have a description'
        end

        def scan_directory_for_components
          return if Ci::Catalog::ComponentsProject.new(project).fetch_component_paths(ref,
            limit: MINIMUM_AMOUNT_OF_COMPONENTS).any?

          errors << 'Project must contain components. Ensure you are using the correct directory structure'
        end

        def project_has_readme?
          project.repository.blob_data_at(ref, 'README.md')
        end
      end
    end
  end
end

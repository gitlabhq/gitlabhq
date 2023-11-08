# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      class ReleaseService
        def initialize(release)
          @release = release
          @project = release.project
          @errors = []
        end

        def execute
          validate_catalog_resource
          create_version

          if errors.empty?
            ServiceResponse.success
          else
            ServiceResponse.error(message: errors.join(', '))
          end
        end

        private

        attr_reader :project, :errors, :release

        def validate_catalog_resource
          response = Ci::Catalog::Resources::ValidateService.new(project, release.sha).execute
          return if response.success?

          errors << response.message
        end

        def create_version
          return if errors.present?

          response = Ci::Catalog::Resources::Versions::CreateService.new(release).execute
          return if response.success?

          errors << response.message
        end
      end
    end
  end
end

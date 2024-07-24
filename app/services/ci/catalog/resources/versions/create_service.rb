# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      module Versions
        class CreateService
          def initialize(release)
            @release = release
            @project = release.project
            @errors = []
          end

          def execute
            version = build_catalog_resource_version
            build_components(version)
            publish(version)

            if errors.empty?
              ServiceResponse.success
            else
              ServiceResponse.error(message: errors.flatten.first(10).join(', '))
            end
          end

          private

          attr_reader :project, :errors, :release

          def build_catalog_resource_version
            return error('Project is not a catalog resource') unless project.catalog_resource

            Ci::Catalog::Resources::Version.new(
              release: release,
              catalog_resource: project.catalog_resource,
              project: project,
              semver: release.tag
            )
          end

          def build_components(version)
            return if errors.present?

            response = BuildComponentsService.new(release, version).execute

            if response.success?
              version.components = response.payload
            else
              error(response.message)
            end
          end

          def publish(version)
            return if errors.present?

            ::Ci::Catalog::Resources::Version.transaction do
              BulkInsertableAssociations.with_bulk_insert do
                version.save!
              end

              project.catalog_resource.publish!
            end
          end

          def error(message)
            errors << message
          end
        end
      end
    end
  end
end

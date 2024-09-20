# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      module Versions
        class CreateService
          def initialize(release, user, metadata)
            @release = release
            @user = user
            @project = release.project
            @metadata = metadata
            @errors = []
          end

          def execute
            version = build_catalog_resource_version
            build_components(version)
            publish(version)

            if errors.empty?
              ServiceResponse.success(payload: { version: version })
            else
              ServiceResponse.error(message: errors.flatten.first(10).join(', '))
            end
          end

          private

          attr_reader :project, :errors, :release, :user, :metadata

          def build_catalog_resource_version
            return error('Project is not a catalog resource') unless project.catalog_resource

            version = Ci::Catalog::Resources::Version.new(
              published_by: user,
              release: release,
              catalog_resource: project.catalog_resource,
              project: project,
              semver: release.tag
            )

            error(version.errors.full_messages) unless version.valid?

            version
          end

          def build_components(version)
            return if errors.present?

            # metadata is passed as `nil` from the `Releases::CreateService`.
            response = BuildComponentsService.new(release, version, metadata.try(:[], :components)).execute

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

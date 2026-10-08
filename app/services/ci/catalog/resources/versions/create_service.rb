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
            bundle = collect_bundle(version)
            publish(version, bundle)

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

          def collect_bundle(version)
            return if errors.present?
            return unless collect_bundle?

            response = ::Ci::Catalog::BundledResources::CollectAndStoreService.new(version).prepare
            return response.payload if response.success?

            error(response.message)
            nil
          rescue StandardError => e
            ::Gitlab::ErrorTracking.track_exception(e, project_id: project.id)
            error('Catalog bundle could not be stored')
            nil
          end

          def collect_bundle?
            project.catalog_resource.gitlab_maintained? &&
              ::Feature.enabled?(:ci_collect_bundles_on_publish, project)
          end

          def publish(version, bundle)
            return if errors.present?

            ::Ci::Catalog::Resources::Version.transaction do
              BulkInsertableAssociations.with_bulk_insert do
                version.save!
              end

              project.catalog_resource.publish!
              ::Ci::Catalog::BundledResources::CollectAndStoreService.new(version).persist(bundle) if bundle
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

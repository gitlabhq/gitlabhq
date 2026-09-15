# frozen_string_literal: true

module Ci
  module Catalog
    module BundledResources
      # Compiles as the version's `published_by`, so a bundle can never carry
      # content its publisher could not read.
      class CompileAndStoreService
        include Gitlab::Utils::StrongMemoize

        def initialize(version)
          @version = version
        end

        def execute
          compiled = ::Ci::Catalog::Resources::Bundle::CompileService.new(version).execute
          return compiled unless compiled.success?

          store(compiled.payload[:components])
        end

        private

        attr_reader :version

        # Documents are uploaded before any row is written, so a failed upload cannot
        # leave rows pointing at a document that was never stored. The object key is
        # derived from the natural key, so a retry overwrites instead of accumulating.
        def store(compiled_components)
          readme = version.readme
          documents = upload_documents(compiled_components)

          bundled_resource, bundled_version = ::Ci::Catalog::BundledResource.transaction do
            resource = upsert_bundled_resource
            row = upsert_version_row(resource)
            upsert_components(documents, resource, row)
            row.update!(readme: readme)
            resource.update!(latest_released_at: resource.versions.latest&.released_at)

            [resource, row]
          end

          ServiceResponse.success(
            payload: {
              bundled_resource: bundled_resource,
              version: bundled_version,
              components: bundled_version.components.reset.to_a
            }
          )
        end

        def upload_documents(compiled_components)
          compiled_components.map do |compiled|
            component = ::Ci::Catalog::BundledResources::Component.new(
              name: compiled[:name],
              spec: spec_for(compiled[:name]),
              bundled_resource: key_resource,
              version: key_version
            )
            component.file = ::CarrierWaveStringFile.new_file(
              file_content: compiled[:content],
              filename: compiled[:name],
              content_type: 'application/x-yaml'
            )

            component.validate!
            component.store_file!
            component.write_file_identifier

            {
              name: component.name,
              spec: component.spec,
              file: component[:file],
              file_store: component.file.object_store
            }
          end
        end

        def upsert_components(documents, bundled_resource, bundled_version)
          return if documents.empty?

          now = Time.current
          rows = documents.map do |document|
            document.merge(
              catalog_bundled_resource_id: bundled_resource.id,
              catalog_bundled_version_id: bundled_version.id,
              created_at: now
            )
          end

          ::Ci::Catalog::BundledResources::Component.upsert_all(
            rows,
            unique_by: %i[catalog_bundled_version_id name],
            update_only: %i[spec file file_store]
          )
        end

        # Unsaved, and carries only what ObjectKey reads off the records.
        def key_resource
          ::Ci::Catalog::BundledResource.new(
            server_fqdn: server_fqdn,
            full_path: version.project.full_path
          )
        end
        strong_memoize_attr :key_resource

        def key_version
          ::Ci::Catalog::BundledResources::Version.new(**semver_attributes)
        end
        strong_memoize_attr :key_version

        def upsert_bundled_resource
          upsert_and_find(
            ::Ci::Catalog::BundledResource,
            {
              server_fqdn: server_fqdn,
              full_path: version.project.full_path,
              name: catalog_resource.name,
              description: catalog_resource.description,
              latest_released_at: version.released_at
            },
            unique_by: [:server_fqdn, :full_path],
            # `latest_released_at` is recomputed from the version rows after the
            # version upsert, so it is deliberately not touched here.
            on_duplicate: Arel.sql(<<~SQL.squish)
              name = excluded.name,
              description = excluded.description,
              updated_at = excluded.updated_at
            SQL
          )
        end

        def upsert_version_row(bundled_resource)
          upsert_and_find(
            ::Ci::Catalog::BundledResources::Version,
            {
              catalog_bundled_resource_id: bundled_resource.id,
              released_at: version.released_at,
              **semver_attributes
            },
            unique_by: %i[catalog_bundled_resource_id semver_major semver_minor semver_patch semver_prerelease]
          )
        end

        # `semver_prefixed` is copied because ObjectKey's path uses semver.to_s,
        # which re-adds the `v` only when prefixed.
        def semver_attributes
          {
            semver_major: version.semver_major,
            semver_minor: version.semver_minor,
            semver_patch: version.semver_patch,
            semver_prerelease: version.semver_prerelease,
            semver_prefixed: version.semver_prefixed
          }
        end

        def spec_for(name)
          spec = source_specs[name]
          return spec if spec

          ::Gitlab::AppLogger.info(
            message: 'Bundled catalog component has no published spec',
            catalog_resource_version_id: version.id,
            component_name: name
          )

          {}
        end

        def source_specs
          version.components.to_h { |component| [component.name, component.spec] }
        end
        strong_memoize_attr :source_specs

        def upsert_and_find(model, attributes, unique_by:, **options)
          id = model.upsert(
            attributes, unique_by: unique_by, returning: %w[id], **options
          ).rows.flatten.first

          model.find(id)
        end

        def catalog_resource
          version.catalog_resource
        end

        def server_fqdn
          ::Gitlab.config.gitlab.server_fqdn
        end
      end
    end
  end
end

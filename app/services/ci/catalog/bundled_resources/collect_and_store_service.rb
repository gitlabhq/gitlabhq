# frozen_string_literal: true

module Ci
  module Catalog
    module BundledResources
      # Collection fails unless anyone can download the project's code, because a
      # bundle can be read by any project on a Cell.
      class CollectAndStoreService
        include Gitlab::Utils::StrongMemoize

        def initialize(version)
          @version = version
        end

        def execute
          bundled_version = find_collected_version
          return success(bundled_version.bundled_resource, bundled_version) if bundled_version

          uploaded_bundles = prepare
          return uploaded_bundles unless uploaded_bundles.success?

          ::Ci::Catalog::BundledResource.transaction { persist(uploaded_bundles.payload) }
        end

        # Documents are uploaded before any row is written, so a failed upload cannot
        # leave rows pointing at a document that was never stored. The object key is
        # derived from the natural key, so a retry overwrites instead of accumulating.
        def prepare
          unless Ability.allowed?(nil, :download_code, version.project)
            return ServiceResponse.error(message: 'Catalog resource is not public', reason: :not_public)
          end

          collected_bundles = ::Ci::Catalog::Resources::Bundle::CollectService.new(version).execute
          return collected_bundles unless collected_bundles.success?

          ServiceResponse.success(
            payload: {
              readme: version.readme,
              documents: upload_documents(collected_bundles.payload[:components])
            }
          )
        end

        def persist(prepared)
          bundled_resource = upsert_bundled_resource
          bundled_version = upsert_version_row(bundled_resource)

          upsert_components(prepared[:documents], bundled_resource, bundled_version)

          bundled_version.update!(readme: prepared[:readme])
          bundled_resource.update!(latest_released_at: bundled_resource.versions.latest&.released_at)

          success(bundled_resource, bundled_version)
        end

        private

        attr_reader :version

        def find_collected_version
          ::Ci::Catalog::BundledResource.find_bundled_version(
            server_fqdn: server_fqdn,
            full_path: version.project.full_path,
            semver: version.semver
          )
        end

        def success(bundled_resource, bundled_version)
          ServiceResponse.success(
            payload: {
              bundled_resource: bundled_resource,
              version: bundled_version,
              components: bundled_version.components.reset.to_a
            }
          )
        end

        def upload_documents(collected_components)
          collected_components.map do |collected|
            component = ::Ci::Catalog::BundledResources::Component.new(
              name: collected[:name],
              spec: spec_for(collected[:name]),
              bundled_resource: key_resource,
              version: key_version
            )
            component.file = ::CarrierWaveStringFile.new_file(
              file_content: collected[:content],
              filename: collected[:name],
              content_type: 'application/json'
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

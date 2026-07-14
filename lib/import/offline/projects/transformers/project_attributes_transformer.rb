# frozen_string_literal: true

module Import
  module Offline
    module Projects
      module Transformers
        class ProjectAttributesTransformer
          include ::BulkImports::PathNormalization
          include ::BulkImports::Uniquify

          NamespaceNotFoundError = Class.new(StandardError)

          def transform(context, data)
            return unless data

            entity = context.entity
            namespace = entity.bulk_import.organization.namespaces.find_by_full_path(entity.destination_namespace)

            unless namespace
              raise(
                NamespaceNotFoundError,
                "Destination namespace '#{entity.destination_namespace}' not found in the import organization"
              )
            end

            path = normalize_path(entity.destination_slug)

            clean_attributes(data).merge(
              name: uniquify(namespace, data['name'], :name),
              path: uniquify(namespace, path, :path),
              created_at: data['created_at'],
              import_type: Import::SOURCE_OFFLINE_TRANSFER.to_s,
              visibility_level: allowed_visibility_level(data['visibility_level'], namespace),
              namespace_id: namespace.id
            ).with_indifferent_access
          end

          private

          def allowed_visibility_level(level, namespace)
            namespace_level = namespace.visibility_level
            lowest_level = [level, namespace_level].compact.min

            Gitlab::VisibilityLevel.closest_allowed_level(lowest_level)
          end

          def clean_attributes(data)
            config = ::BulkImports::FileTransfer.config_for(::Project.new)
            subrelations = config.portable_relations_tree.keys.map(&:to_s)

            ::Gitlab::ImportExport::AttributeCleaner.clean(
              relation_hash: data,
              relation_class: ::Project,
              excluded_keys: config.relation_excluded_keys(:project)
            ).except(*subrelations)
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Namespaces
  module Preloaders
    class NamespaceRootAncestorPreloader
      include Gitlab::Loggable

      def initialize(namespaces, root_ancestor_preloads = [])
        @namespaces = namespaces.uniq.compact
        @root_ancestor_preloads = root_ancestor_preloads
      end

      def execute
        root_query = Namespace.joins("INNER JOIN (#{join_sql}) as root_query ON root_query.root_id = namespaces.id")
                          .select('namespaces.*, root_query.id as source_id')

        root_query = root_query.preload(*@root_ancestor_preloads) if @root_ancestor_preloads.any?

        root_ancestors_by_id = root_query.group_by(&:source_id)

        @namespaces.each do |namespace|
          root_ancestor = root_ancestors_by_id[namespace.id]&.first

          if root_ancestor
            namespace.root_ancestor = root_ancestor
          else
            log_orphaned_namespace(namespace)
          end
        end
      end

      private

      def log_orphaned_namespace(namespace)
        Gitlab::AppLogger.warn(
          build_structured_payload(
            message: 'Orphaned namespace detected. Unable to find root ancestor',
            namespace_id: namespace.id,
            namespace_type: namespace.type,
            namespace_path: namespace.path,
            traversal_ids: namespace.traversal_ids
          )
        )
      end

      def join_sql
        Namespace.select('id, traversal_ids[1] as root_id').where(id: @namespaces.map(&:id)).to_sql
      end
    end
  end
end

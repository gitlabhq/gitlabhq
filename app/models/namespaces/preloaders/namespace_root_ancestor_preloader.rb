# frozen_string_literal: true

module Namespaces
  module Preloaders
    class NamespaceRootAncestorPreloader
      def initialize(namespaces, root_ancestor_preloads = [])
        @namespaces = namespaces
        @root_ancestor_preloads = root_ancestor_preloads
      end

      def execute
        root_query = Namespace.joins("INNER JOIN (#{join_sql}) as root_query ON root_query.root_id = namespaces.id")
                          .select('namespaces.*, root_query.id as source_id')

        root_query = root_query.preload(*@root_ancestor_preloads) if @root_ancestor_preloads.any?

        root_ancestors_by_id = root_query.group_by(&:source_id)

        @namespaces.each do |namespace|
          namespace.root_ancestor = root_ancestors_by_id[namespace.id].first
        end
      end

      private

      def join_sql
        Namespace.select('id, traversal_ids[1] as root_id').where(id: @namespaces.map(&:id)).to_sql
      end
    end
  end
end

# frozen_string_literal: true

module Security
  # This model represents a record in a shadow table of the main database's namespaces table.
  # It is used for finding the organization_id for namespace-related data in SEC database
  class NamespaceMirror < SecApplicationRecord
    self.table_name = 'sec_namespace_mirrors'
    self.primary_key = :namespace_id

    belongs_to :namespace

    class << self
      def sync!(event)
        namespace = event.namespace
        traversal_ids = namespace.self_and_ancestor_ids(hierarchy_order: :desc)

        upsert(
          {
            namespace_id: event.namespace_id,
            traversal_ids: traversal_ids,
            organization_id: namespace.organization_id
          },
          unique_by: :namespace_id
        )
      end
    end
  end
end

# frozen_string_literal: true

module Security
  # This model represents a record in a shadow table of the main database's namespaces table.
  # It is used for finding the organization_id for namespace-related data in SEC database
  class NamespaceMirror < SecApplicationRecord
    self.table_name = 'sec_namespace_mirrors'
    self.primary_key = :namespace_id

    belongs_to :namespace
  end
end

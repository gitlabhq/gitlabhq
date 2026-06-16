# frozen_string_literal: true

module LooseForeignKeys
  class NamespaceDeletedRecord < Gitlab::Database::SharedModel
    include DeletedRecordConcern

    self.table_name = 'loose_foreign_keys_namespace_deleted_records'

    validates :namespace_id, presence: true
  end
end

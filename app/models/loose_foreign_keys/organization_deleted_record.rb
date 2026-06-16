# frozen_string_literal: true

module LooseForeignKeys
  class OrganizationDeletedRecord < Gitlab::Database::SharedModel
    include DeletedRecordConcern

    self.table_name = 'loose_foreign_keys_organization_deleted_records'

    validates :organization_id, presence: true
  end
end

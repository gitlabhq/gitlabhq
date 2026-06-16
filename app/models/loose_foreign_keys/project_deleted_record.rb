# frozen_string_literal: true

module LooseForeignKeys
  class ProjectDeletedRecord < Gitlab::Database::SharedModel
    include DeletedRecordConcern

    self.table_name = 'loose_foreign_keys_project_deleted_records'

    validates :project_id, presence: true
  end
end

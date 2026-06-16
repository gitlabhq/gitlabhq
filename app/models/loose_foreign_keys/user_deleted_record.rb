# frozen_string_literal: true

module LooseForeignKeys
  class UserDeletedRecord < Gitlab::Database::SharedModel
    include DeletedRecordConcern

    self.table_name = 'loose_foreign_keys_user_deleted_records'

    validates :user_id, presence: true
  end
end

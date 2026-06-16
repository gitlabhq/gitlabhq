# frozen_string_literal: true

module LooseForeignKeys
  class DeletedRecord < Gitlab::Database::SharedModel
    include DeletedRecordConcern
  end
end

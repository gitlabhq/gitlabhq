# frozen_string_literal: true

class RemoveWikiNotes < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  class Note < ApplicationRecord
    self.table_name = 'notes'
    self.inheritance_column = :_type_disabled
  end

  def up
    return unless Gitlab.dev_or_test_env? || Gitlab.staging? || Gitlab.com?

    Note.where(noteable_type: 'Wiki', id: [97, 98, 110, 242, 272]).delete_all
  end

  def down
    # NO-OP
  end
end

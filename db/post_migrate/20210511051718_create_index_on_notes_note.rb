# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateIndexOnNotesNote < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DUPLICATE_INDEX_NAME = 'index_notes_on_note_gin_trigram'
  CURRENT_INDEX_NAME = 'index_notes_on_note_trigram'

  disable_ddl_transaction!

  # https://gitlab.com/gitlab-org/gitlab/-/issues/218410#note_565624409
  # We are having troubles with the index, and some inserts are taking a long time
  # so in this migration we are recreating the index
  def up
    add_concurrent_index :notes, :note, name: DUPLICATE_INDEX_NAME, using: :gin, opclass: :gin_trgm_ops
    remove_concurrent_index_by_name :notes, CURRENT_INDEX_NAME
  end

  def down
    add_concurrent_index :notes, :note, name: CURRENT_INDEX_NAME, using: :gin, opclass: :gin_trgm_ops
    remove_concurrent_index_by_name :notes, DUPLICATE_INDEX_NAME
  end
end

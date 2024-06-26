# frozen_string_literal: true

class ReAddTagsNameUniqueIndex < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.2'

  INDEX_NAME = 'index_tags_on_name'

  def up
    return if index_exists_by_name?(:tags, INDEX_NAME)

    # If this index results in a failure due to duplicate keys, then the tags table will need to be de-duped with
    # the script at https://gitlab.com/gitlab-org/gitlab/-/snippets/3700665
    add_concurrent_index :tags, :name, unique: true, name: INDEX_NAME
  rescue ActiveRecord::RecordNotUnique, PG::UniqueViolation => e
    raise StandardError, "Failed to add unique index #{INDEX_NAME}. " \
      "Please refer to https://docs.gitlab.com/runner/faq/#no-unique-index-found-for-name for instructions " \
      "on how to de-duplicate the tags table.\n\n#{e}", e.backtrace
  end

  def down
    # No-op, the index should exist in the schema prior this migration
  end
end

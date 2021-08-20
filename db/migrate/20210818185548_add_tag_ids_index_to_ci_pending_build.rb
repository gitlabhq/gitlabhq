# frozen_string_literal: true

class AddTagIdsIndexToCiPendingBuild < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_pending_builds_on_tag_ids'

  def up
    add_concurrent_index(:ci_pending_builds, :tag_ids, name: INDEX_NAME, where: 'cardinality(tag_ids) > 0')
  end

  def down
    remove_concurrent_index_by_name(:ci_pending_builds, name: INDEX_NAME)
  end
end

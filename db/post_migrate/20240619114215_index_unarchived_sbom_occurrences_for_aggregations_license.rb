# frozen_string_literal: true

class IndexUnarchivedSbomOccurrencesForAggregationsLicense < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'index_unarchived_occurrences_for_aggregations_license'

  milestone '17.2'

  disable_ddl_transaction!

  # rubocop:disable Migration/PreventIndexCreation -- Once complete, this index unblocks the removal of other indexes https://gitlab.com/gitlab-org/gitlab/-/issues/442486
  def up
    add_concurrent_index :sbom_occurrences,
      "traversal_ids, (licenses -> 0 ->> 'spdx_identifier'), component_id, component_version_id",
      where: 'archived = false',
      name: INDEX_NAME
  end
  # rubocop:enable Migration/PreventIndexCreation

  def down
    remove_concurrent_index_by_name :sbom_occurrences, INDEX_NAME
  end
end

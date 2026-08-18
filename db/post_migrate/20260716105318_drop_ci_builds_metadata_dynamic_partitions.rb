# frozen_string_literal: true

class DropCiBuildsMetadataDynamicPartitions < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  TABLE_NAMES = [
    'gitlab_partitions_dynamic.ci_builds_metadata',
    'gitlab_partitions_dynamic.ci_builds_metadata_101',
    'gitlab_partitions_dynamic.ci_builds_metadata_102',
    'gitlab_partitions_dynamic.ci_builds_metadata_103',
    'gitlab_partitions_dynamic.ci_builds_metadata_104',
    'gitlab_partitions_dynamic.ci_builds_metadata_105',
    'gitlab_partitions_dynamic.ci_builds_metadata_106',
    'gitlab_partitions_dynamic.ci_builds_metadata_107'
  ].freeze

  def up
    TABLE_NAMES.each { |table_name| drop_table table_name, if_exists: true }
  end

  def down
    # no-op: detached partitions are intentionally not recreated
  end
end

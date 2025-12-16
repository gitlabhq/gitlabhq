# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddPartitionIdToSbomOccurrences < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.6'

  def up
    with_lock_retries do
      # rubocop:disable Migration/PreventAddingColumns -- needed to partition the table which is already over the limit
      add_column :sbom_occurrences, :partition_id, :bigint, default: 1, if_not_exists: true
      # rubocop:enable Migration/PreventAddingColumns
    end
  end

  def down
    with_lock_retries do
      remove_column :sbom_occurrences, :partition_id, :bigint, if_exists: true
    end
  end
end

# frozen_string_literal: true

# rubocop:disable Migration/ChangeColumnNullOnHighTrafficTable -- The cop is introduced after this migration.
class RemoveNotNullConstraintFromTraversalIdsIfExists < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.11'

  class VulnerabilityReads < MigrationRecord
    self.table_name = 'vulnerability_reads'

    def self.traversal_ids_not_null?
      !traversal_ids_column.null
    end

    def self.traversal_ids_column
      reset_column_information

      columns.find { |c| c.name == 'traversal_ids' }
    end
  end

  def up
    change_column_null(:vulnerability_reads, :traversal_ids, true) if VulnerabilityReads.traversal_ids_not_null?
  end

  def down
    # no-op
  end
end
# rubocop:enable Migration/ChangeColumnNullOnHighTrafficTable

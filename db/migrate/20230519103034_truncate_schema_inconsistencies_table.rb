# frozen_string_literal: true

class TruncateSchemaInconsistenciesTable < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    truncate_tables!('schema_inconsistencies')
  end

  def down
    # no-op
  end
end

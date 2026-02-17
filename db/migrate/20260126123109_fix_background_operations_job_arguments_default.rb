# frozen_string_literal: true

class FixBackgroundOperationsJobArgumentsDefault < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  disable_ddl_transaction!

  def up
    %i[background_operation_workers background_operation_workers_cell_local].each do |table_name|
      change_column_default table_name, :job_arguments, []
    end
  end

  def down
    %i[background_operation_workers background_operation_workers_cell_local].each do |table_name|
      change_column_default table_name, :job_arguments, '[]'
    end
  end
end

# frozen_string_literal: true

class DropNotNullConstraintOnMrdfPartitionNewPathColumn < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.4'

  def up
    change_column_null :merge_request_diff_files_99208b8fac, :new_path, true
  end

  def down
    change_column_null :merge_request_diff_files_99208b8fac, :new_path, false
  end
end

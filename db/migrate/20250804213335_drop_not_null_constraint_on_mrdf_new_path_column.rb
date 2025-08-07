# frozen_string_literal: true

class DropNotNullConstraintOnMrdfNewPathColumn < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.3'

  def up
    change_column_null :merge_request_diff_files, :new_path, true
  end

  def down
    # rubocop:disable Migration/ChangeColumnNullOnHighTrafficTable -- legacy table w/o CONSTRAINT
    change_column_null :merge_request_diff_files, :new_path, false
    # rubocop:enable Migration/ChangeColumnNullOnHighTrafficTable
  end
end

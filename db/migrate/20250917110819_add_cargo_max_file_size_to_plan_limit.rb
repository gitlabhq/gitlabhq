# frozen_string_literal: true

class AddCargoMaxFileSizeToPlanLimit < Gitlab::Database::Migration[2.3]
  milestone '18.5'
  disable_ddl_transaction!

  def up
    add_column :plan_limits, :cargo_max_file_size, :bigint, default: 5.gigabytes, null: false
  end

  def down
    remove_column :plan_limits, :cargo_max_file_size, if_exists: true
  end
end

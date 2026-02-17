# frozen_string_literal: true

class ValidateUserDetailsCompanyTextLimit < Gitlab::Database::Migration[2.3]
  milestone '18.9'
  disable_ddl_transaction!

  CONSTRAINT = 'check_3b9aec5742'

  def up
    prepare_async_check_constraint_validation :user_details, name: CONSTRAINT
  end

  def down
    unprepare_async_check_constraint_validation :user_details, name: CONSTRAINT
  end
end

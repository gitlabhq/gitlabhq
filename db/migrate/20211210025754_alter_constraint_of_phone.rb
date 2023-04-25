# frozen_string_literal: true

class AlterConstraintOfPhone < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    constraint_phone = check_constraint_name('verification_codes', 'phone', 'max_length')
    remove_check_constraint(:verification_codes, constraint_phone)
    add_check_constraint(:verification_codes, 'char_length(phone) <= 50', constraint_phone)
  end

  def down
    constraint_phone = check_constraint_name('verification_codes', 'phone', 'max_length')
    remove_check_constraint(:verification_codes, constraint_phone)
    add_check_constraint(:verification_codes, 'char_length(phone) <= 32', constraint_phone)
  end
end

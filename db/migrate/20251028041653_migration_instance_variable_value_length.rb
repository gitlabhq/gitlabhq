# frozen_string_literal: true

class MigrationInstanceVariableValueLength < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  disable_ddl_transaction!

  def up
    # The encrypted size is the actual length + 16 bytes for AES-GCM overhead,
    # plus 1/3 for base encoding:
    #     (10_000 + 16) / 3 * 4 with a bit of padding => 13_579
    #     (50_000 + 16) / 3 * 4  with a bit of padding => 67_800
    # using debugger to get the actual length of encrypted value is the
    # simplest way to get the value.
    add_check_constraint :ci_instance_variables,
      '((variable_type = 2) AND (char_length(encrypted_value) <= 67800))
                         OR (char_length(encrypted_value) <= 13579)',
      :check_956afd70f2

    # Remove the existing constraint after adding the new one
    remove_check_constraint :ci_instance_variables, :check_956afd70f1
  end

  def down
    # Restore the original constraint first
    add_check_constraint :ci_instance_variables,
      'char_length(encrypted_value) <= 13579',
      :check_956afd70f1

    # Remove the conditional constraint after restoring the original constraint
    remove_check_constraint :ci_instance_variables, :check_956afd70f2
  end
end

# frozen_string_literal: true

class AddCheckConstraintForSecurityFindingsPartitionNumber < Gitlab::Database::Migration[2.0]
  CONSTRAINT_NAME = 'check_partition_number'

  disable_ddl_transaction!

  def up
    add_check_constraint(:security_findings, 'partition_number = 1', CONSTRAINT_NAME)
  end

  def down
    remove_check_constraint(:security_findings, CONSTRAINT_NAME)
  end
end

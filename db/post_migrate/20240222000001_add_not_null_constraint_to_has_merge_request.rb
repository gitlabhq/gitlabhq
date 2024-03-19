# frozen_string_literal: true

class AddNotNullConstraintToHasMergeRequest < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.10'

  def up
    add_not_null_constraint :vulnerability_reads, :has_merge_request
  end

  def down
    remove_not_null_constraint :vulnerability_reads, :has_merge_request
  end
end

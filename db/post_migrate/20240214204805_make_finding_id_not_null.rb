# frozen_string_literal: true

class MakeFindingIdNotNull < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.9'

  def up
    add_not_null_constraint :vulnerabilities, :finding_id
  end

  def down
    remove_not_null_constraint :vulnerabilities, :finding_id
  end
end

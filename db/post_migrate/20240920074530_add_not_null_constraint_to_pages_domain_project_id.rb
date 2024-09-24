# frozen_string_literal: true

class AddNotNullConstraintToPagesDomainProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :pages_domains, :project_id
  end

  def down
    remove_not_null_constraint :pages_domains, :project_id
  end
end

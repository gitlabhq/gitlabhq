# frozen_string_literal: true

class ChangeOrganizationsSequence < Gitlab::Database::Migration[2.1]
  def up
    # Modify sequence for organizations.id so id '1' is never automatically taken
    execute "ALTER SEQUENCE organizations_id_seq START WITH 1000 MINVALUE 1000 RESTART"
  end

  def down
    execute "ALTER SEQUENCE organizations_id_seq START WITH 1 MINVALUE 1"
  end
end

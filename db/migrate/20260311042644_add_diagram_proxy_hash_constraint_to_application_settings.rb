# frozen_string_literal: true

class AddDiagramProxyHashConstraintToApplicationSettings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.10'

  CONSTRAINT_NAME = 'check_application_settings_diagram_proxy_is_hash'

  def up
    add_check_constraint(
      :application_settings,
      "(jsonb_typeof(diagram_proxy) = 'object')",
      CONSTRAINT_NAME
    )
  end

  def down
    remove_check_constraint :application_settings, CONSTRAINT_NAME
  end
end

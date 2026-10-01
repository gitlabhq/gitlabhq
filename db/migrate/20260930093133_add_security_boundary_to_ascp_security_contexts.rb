# frozen_string_literal: true

# See https://docs.gitlab.com/development/migration_style_guide/
# for more information on how to write migrations for GitLab.

class AddSecurityBoundaryToAscpSecurityContexts < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  def change
    add_column :ascp_security_contexts, :security_boundary, :text,
      array: true, null: false, default: []
  end
end

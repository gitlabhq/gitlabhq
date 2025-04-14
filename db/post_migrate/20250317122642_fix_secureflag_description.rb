# frozen_string_literal: true

class FixSecureflagDescription < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    execute <<~SQL
      UPDATE security_training_providers SET description = 'Get remediation advice with example code and recommended hands-on labs in a fully
      interactive virtualized environment.'
      WHERE name = 'SecureFlag'
    SQL
  end

  def down
    # No-op
  end
end

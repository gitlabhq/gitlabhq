# frozen_string_literal: true

class UpdateWorkspacesUrlPrefixColumn < Gitlab::Database::Migration[2.2]
  milestone '16.8'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    execute(<<~SQL)
      UPDATE workspaces
      SET url_prefix=REPLACE(url_prefix, 'https://', '')
      WHERE url_prefix LIKE 'https://%'
    SQL
  end

  def down
    # no-op
  end
end

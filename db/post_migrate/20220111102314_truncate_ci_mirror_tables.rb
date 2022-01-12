# frozen_string_literal: true

class TruncateCiMirrorTables < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    execute('TRUNCATE TABLE ci_namespace_mirrors')
    execute('TRUNCATE TABLE ci_project_mirrors')
  end

  def down
    # noop
  end
end

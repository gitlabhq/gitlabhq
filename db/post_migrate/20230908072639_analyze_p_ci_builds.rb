# frozen_string_literal: true

class AnalyzePCiBuilds < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    disable_statement_timeout do
      execute('ANALYZE VERBOSE p_ci_builds;')
    end
  end

  def down
    # no-op
  end
end

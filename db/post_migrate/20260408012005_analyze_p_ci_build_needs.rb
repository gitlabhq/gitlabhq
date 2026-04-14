# frozen_string_literal: true

class AnalyzePCiBuildNeeds < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def up
    disable_statement_timeout do
      execute("ANALYZE VERBOSE #{quote_table_name(:p_ci_build_needs)}")
    end
  end

  def down
    # no-op
  end
end

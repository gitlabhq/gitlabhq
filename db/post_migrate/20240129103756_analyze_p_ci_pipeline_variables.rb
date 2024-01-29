# frozen_string_literal: true

class AnalyzePCiPipelineVariables < Gitlab::Database::Migration[2.2]
  milestone '16.9'
  disable_ddl_transaction!

  def up
    disable_statement_timeout do
      execute('ANALYZE VERBOSE p_ci_pipeline_variables;')
    end
  end

  def down
    # no-op
  end
end

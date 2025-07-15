# frozen_string_literal: true

class AddProvenanceStatementPlanLimit < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  def change
    add_column :plan_limits, :ci_max_artifact_size_slsa_provenance_statement, :bigint, default: 0, null: false
  end
end

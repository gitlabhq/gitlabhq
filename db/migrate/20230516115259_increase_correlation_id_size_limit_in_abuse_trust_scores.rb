# frozen_string_literal: true

class IncreaseCorrelationIdSizeLimitInAbuseTrustScores < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    constraint_correlation_id = check_constraint_name('abuse_trust_scores', 'correlation_id_value', 'max_length')
    remove_check_constraint(:abuse_trust_scores, constraint_correlation_id)
    add_check_constraint(:abuse_trust_scores, 'char_length(correlation_id_value) <= 255', constraint_correlation_id)
  end

  def down
    constraint_correlation_id = check_constraint_name('abuse_trust_scores', 'correlation_id_value', 'max_length')
    remove_check_constraint(:abuse_trust_scores, constraint_correlation_id)
    add_check_constraint(:abuse_trust_scores, 'char_length(correlation_id_value) <= 32', constraint_correlation_id)
  end
end

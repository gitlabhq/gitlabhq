# frozen_string_literal: true

class RemoveConfidenceColumnFromSecurityFindings < Gitlab::Database::Migration[2.2]
  milestone '17.8'

  def up
    remove_column :security_findings, :confidence
  end

  def down
    add_column :security_findings, :confidence, :smallint
  end
end

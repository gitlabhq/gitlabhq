# frozen_string_literal: true

class RemoveConfidenceColumnsFromVulnerabilties < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def up
    remove_column :vulnerabilities, :confidence
    remove_column :vulnerabilities, :confidence_overridden
  end

  def down
    add_column :vulnerabilities, :confidence, :smallint
    add_column :vulnerabilities, :confidence_overridden, :boolean, default: false
  end
end

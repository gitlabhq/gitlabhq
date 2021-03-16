# frozen_string_literal: true

class ChangeFindingFingerprintEnum < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    change_column :vulnerability_finding_fingerprints, :algorithm_type, :integer, limit: 2
  end

  def down
    change_column :vulnerability_finding_fingerprints, :algorithm_type, :integer
  end
end

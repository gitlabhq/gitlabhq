# frozen_string_literal: true

class CreateProjectSecurityStatisticsTable < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    create_table :project_security_statistics, id: false do |t| # rubocop:disable Migration/EnsureFactoryForTable -- False positive
      t.bigint :project_id, primary_key: true, default: nil
      t.integer :vulnerability_count, default: 0, null: false
    end
  end
end

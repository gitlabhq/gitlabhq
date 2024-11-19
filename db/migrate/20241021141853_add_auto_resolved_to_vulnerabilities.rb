# frozen_string_literal: true

class AddAutoResolvedToVulnerabilities < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def change
    add_column :vulnerabilities, :auto_resolved, :boolean, null: false, default: false, if_not_exists: true
  end
end

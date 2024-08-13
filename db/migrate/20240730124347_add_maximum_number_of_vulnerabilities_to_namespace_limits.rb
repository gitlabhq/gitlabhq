# frozen_string_literal: true

class AddMaximumNumberOfVulnerabilitiesToNamespaceLimits < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def change
    add_column :namespace_limits, :max_number_of_vulnerabilities_per_project, :integer
  end
end

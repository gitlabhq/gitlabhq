# frozen_string_literal: true

class AddMaximumNumberOfVulnerabilitiesToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def change
    add_column :application_settings, :max_number_of_vulnerabilities_per_project, :integer
  end
end

# frozen_string_literal: true

class AddOptionalVariablesToDastSiteProfiles < Gitlab::Database::Migration[2.2]
  milestone '17.8'

  def change
    add_column :dast_site_profiles, :optional_variables, :jsonb, default: [], null: false
  end
end

# frozen_string_literal: true

class AddIdTokenSubClaimComponentsToProjectCiCdSettings < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def change
    add_column :project_ci_cd_settings, :id_token_sub_claim_components, :string,
      array: true, null: false, default: %w[project_path ref_type ref]
  end
end

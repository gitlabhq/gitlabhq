# frozen_string_literal: true

class AddDuoCodeReviewDecisionSettingsToProjectSettings < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  def change
    add_column :project_settings, :duo_code_review_decisions_enabled, :boolean
    add_column :project_settings, :duo_code_review_approval_counts_enabled, :boolean
  end
end

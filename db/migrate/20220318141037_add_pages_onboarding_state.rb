# frozen_string_literal: true

class AddPagesOnboardingState < Gitlab::Database::Migration[1.0]
  def up
    add_column :project_pages_metadata, :onboarding_complete, :boolean, default: false, null: false
  end

  def down
    remove_column :project_pages_metadata, :onboarding_complete
  end
end

# frozen_string_literal: true

class AddFeatureFlagsMinimumRoleToProjectSettings < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  def change
    # Default 2 == developer (see ProjectSetting::FEATURE_FLAGS_MANAGEMENT_ROLES).
    # Developer is the current baseline for managing feature flags, so this
    # default preserves existing behavior for all projects.
    add_column :project_settings, :feature_flags_minimum_role, :integer,
      default: 2, null: false, limit: 2
  end
end

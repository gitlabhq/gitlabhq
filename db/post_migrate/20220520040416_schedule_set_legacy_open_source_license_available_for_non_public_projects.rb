# frozen_string_literal: true

class ScheduleSetLegacyOpenSourceLicenseAvailableForNonPublicProjects < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # Replaced by 20220722110026_reschedule_set_legacy_open_source_license_available_for_non_public_projects.rb
  end

  def down
    # Replaced by 20220722110026_reschedule_set_legacy_open_source_license_available_for_non_public_projects.rb
  end
end

# frozen_string_literal: true

module Admin
  module ApplicationSettings
    module SettingsHelper
      def dormant_projects_deletion_data(settings)
        {
          delete_dormant_projects: settings.delete_inactive_projects.to_s,
          dormant_projects_delete_after_months: settings.inactive_projects_delete_after_months,
          dormant_projects_min_size_mb: settings.inactive_projects_min_size_mb,
          dormant_projects_send_warning_email_after_months: settings.inactive_projects_send_warning_email_after_months
        }
      end
    end
  end
end

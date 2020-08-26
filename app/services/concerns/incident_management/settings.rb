# frozen_string_literal: true

module IncidentManagement
  module Settings
    include Gitlab::Utils::StrongMemoize

    delegate :send_email?, to: :incident_management_setting

    def incident_management_setting
      strong_memoize(:incident_management_setting) do
        project.incident_management_setting ||
          project.build_incident_management_setting
      end
    end

    def process_issues?
      incident_management_setting.create_issue?
    end

    def auto_close_incident?
      incident_management_setting.auto_close_incident?
    end
  end
end

# frozen_string_literal: true
module IncidentManagement
  module Settings
    include Gitlab::Utils::StrongMemoize

    def incident_management_setting
      strong_memoize(:incident_management_setting) do
        project.incident_management_setting ||
          project.build_incident_management_setting
      end
    end

    def process_issues?
      incident_management_setting.create_issue?
    end
  end
end

# frozen_string_literal: true

module Types
  module IncidentManagement
    class EscalationStatusEnum < BaseEnum
      graphql_name 'IssueEscalationStatus'
      description 'Issue escalation status values'

      ::IncidentManagement::IssuableEscalationStatus.status_names.each do |status|
        value status.to_s.upcase, value: status, description: "#{::IncidentManagement::IssuableEscalationStatus::STATUS_DESCRIPTIONS[status]}."
      end
    end
  end
end

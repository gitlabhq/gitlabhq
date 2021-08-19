# frozen_string_literal: true

module IncidentManagement
  class IssuableEscalationStatus < ApplicationRecord
    include ::IncidentManagement::Escalatable

    self.table_name = 'incident_management_issuable_escalation_statuses'

    belongs_to :issue

    validates :issue, presence: true, uniqueness: true
  end
end

IncidentManagement::IssuableEscalationStatus.prepend_mod_with('IncidentManagement::IssuableEscalationStatus')

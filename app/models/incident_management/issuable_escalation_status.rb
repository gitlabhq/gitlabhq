# frozen_string_literal: true

module IncidentManagement
  class IssuableEscalationStatus < ApplicationRecord
    include ::IncidentManagement::Escalatable

    self.table_name = 'incident_management_issuable_escalation_statuses'

    belongs_to :issue
    has_one :project, through: :issue, inverse_of: :incident_management_issuable_escalation_statuses

    validates :issue, presence: true, uniqueness: true

    delegate :project, to: :issue
  end
end

IncidentManagement::IssuableEscalationStatus.prepend_mod_with('IncidentManagement::IssuableEscalationStatus')

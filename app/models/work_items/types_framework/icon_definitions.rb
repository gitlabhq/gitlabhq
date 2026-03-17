# frozen_string_literal: true

module WorkItems
  module TypesFramework
    module IconDefinitions
      ENHANCEMENT = { id: 0, name: 'work-item-enhancement', label: 'Magic wand' }.freeze
      EPIC = { id: 1, name: 'work-item-epic', label: 'Stack' }.freeze
      FLAG = { id: 2, name: 'work-item-feature-flag', label: 'Flag' }.freeze
      FEATURE = { id: 3, name: 'work-item-feature', label: 'Star' }.freeze
      INCIDENT = { id: 4, name: 'work-item-incident', label: 'Exclamation point' }.freeze
      ISSUE = { id: 5, name: 'work-item-issue', label: 'Document' }.freeze
      KEY_RESULT = { id: 6, name: 'work-item-keyresult', label: 'Arrow' }.freeze
      MAINTENANCE = { id: 7, name: 'work-item-maintenance', label: 'Tools' }.freeze
      OBJECTIVE = { id: 8, name: 'work-item-objective', label: 'Target' }.freeze
      REQUIREMENT = { id: 9, name: 'work-item-requirement', label: 'Checklist' }.freeze
      TASK = { id: 10, name: 'work-item-task', label: 'Check' }.freeze
      TEST_CASE = { id: 11, name: 'work-item-test-case', label: 'Test tube' }.freeze
      TICKET = { id: 12, name: 'work-item-ticket', label: 'Ticket' }.freeze
      BUG = { id: 13, name: 'bug', label: 'Insect' }.freeze

      ICON_DEFINITIONS = [
        ENHANCEMENT, EPIC, FLAG, FEATURE, INCIDENT, ISSUE, KEY_RESULT,
        MAINTENANCE, OBJECTIVE, REQUIREMENT, TASK, TEST_CASE, TICKET, BUG
      ].freeze

      ENUM_MAPPING = ICON_DEFINITIONS.to_h { |d| [d[:name], d[:id]] }.freeze
    end
  end
end

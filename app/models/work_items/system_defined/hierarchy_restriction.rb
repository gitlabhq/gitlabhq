# frozen_string_literal: true

module WorkItems
  module SystemDefined
    class HierarchyRestriction
      include ActiveRecord::FixedItemsModel::Model

      attribute :parent_type_id, :integer
      attribute :child_type_id, :integer
      attribute :maximum_depth, :integer

      EPIC_ID = ::WorkItems::Type::BASE_TYPES[:epic][:id]
      ISSUE_ID = ::WorkItems::Type::BASE_TYPES[:issue][:id]
      TASK_ID = ::WorkItems::Type::BASE_TYPES[:task][:id]
      OBJECTIVE_ID = ::WorkItems::Type::BASE_TYPES[:objective][:id]
      KEY_RESULT_ID = ::WorkItems::Type::BASE_TYPES[:key_result][:id]
      INCIDENT_ID = ::WorkItems::Type::BASE_TYPES[:incident][:id]
      TICKET_ID = ::WorkItems::Type::BASE_TYPES[:ticket][:id]

      class << self
        def with_parent_type_id(parent_type_id)
          where(parent_type_id: parent_type_id)
        end

        def hierarchy_relationship_allowed?(parent_type_id:, child_type_id:)
          where(parent_type_id: parent_type_id, child_type_id: child_type_id).present?
        end
      end

      ITEMS = [
        {
          id: 1,
          parent_type_id: OBJECTIVE_ID,
          child_type_id: OBJECTIVE_ID,
          maximum_depth: 9
        },
        {
          id: 2,
          parent_type_id: OBJECTIVE_ID,
          child_type_id: KEY_RESULT_ID,
          maximum_depth: 1
        },
        {
          id: 3,
          parent_type_id: ISSUE_ID,
          child_type_id: TASK_ID,
          maximum_depth: 1
        },
        {
          id: 4,
          parent_type_id: INCIDENT_ID,
          child_type_id: TASK_ID,
          maximum_depth: 1
        },
        {
          id: 5,
          parent_type_id: EPIC_ID,
          child_type_id: EPIC_ID,
          maximum_depth: 7
        },
        {
          id: 6,
          parent_type_id: EPIC_ID,
          child_type_id: ISSUE_ID,
          maximum_depth: 1
        },
        {
          id: 7,
          parent_type_id: TICKET_ID,
          child_type_id: TASK_ID,
          maximum_depth: 1
        }
      ].freeze
    end
  end
end

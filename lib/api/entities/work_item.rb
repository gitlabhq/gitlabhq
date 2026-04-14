# frozen_string_literal: true

module API
  module Entities
    class WorkItem < Issue
      expose :type,
        documentation: {
          type: 'String',
          example: 'TASK',
          desc: 'One of ["ISSUE", "INCIDENT", "TEST_CASE", "REQUIREMENT", "TASK", ' \
            '"OBJECTIVE", "KEY_RESULT", "EPIC", "TICKET"]'
        } do |work_item|
        work_item.work_item_type&.base_type&.upcase
      end
    end
  end
end

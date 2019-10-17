# frozen_string_literal: true

module Types
  class TodoActionEnum < BaseEnum
    value 'assigned', value: 1
    value 'mentioned', value: 2
    value 'build_failed', value: 3
    value 'marked', value: 4
    value 'approval_required', value: 5
    value 'unmergeable', value: 6
    value 'directly_addressed', value: 7
  end
end

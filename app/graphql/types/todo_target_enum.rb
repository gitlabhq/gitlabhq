# frozen_string_literal: true

module Types
  class TodoTargetEnum < BaseEnum
    value 'Issue'
    value 'MergeRequest'
    value 'Epic'
  end
end

# frozen_string_literal: true

module Types
  class TodoTargetEnum < BaseEnum
    value 'COMMIT', value: 'Commit', description: 'A Commit.'
    value 'ISSUE', value: 'Issue', description: 'An Issue.'
    value 'MERGEREQUEST', value: 'MergeRequest', description: 'A MergeRequest.'
    value 'DESIGN', value: 'DesignManagement::Design', description: 'A Design.'
    value 'ALERT', value: 'AlertManagement::Alert', description: 'An Alert.'
  end
end

Types::TodoTargetEnum.prepend_mod_with('Types::TodoTargetEnum')

# frozen_string_literal: true

module Types
  class TodoTargetEnum < BaseEnum
    value 'COMMIT', value: 'Commit', description: 'Commit.'
    value 'ISSUE', value: 'Issue', description: 'Issue.'
    value 'WORKITEM', value: 'WorkItem', description: 'Work item.'
    value 'MERGEREQUEST', value: 'MergeRequest', description: 'Merge request.'
    value 'DESIGN', value: 'DesignManagement::Design', description: 'Design.'
    value 'ALERT', value: 'AlertManagement::Alert', description: 'Alert.'
  end
end

Types::TodoTargetEnum.prepend_mod_with('Types::TodoTargetEnum')

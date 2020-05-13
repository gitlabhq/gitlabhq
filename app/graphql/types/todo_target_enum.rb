# frozen_string_literal: true

module Types
  class TodoTargetEnum < BaseEnum
    value 'COMMIT', value: 'Commit', description: 'A Commit'
    value 'ISSUE', value: 'Issue', description: 'An Issue'
    value 'MERGEREQUEST', value: 'MergeRequest', description: 'A MergeRequest'
    value 'DESIGN', value: 'DesignManagement::Design', description: 'A Design'
  end
end

Types::TodoTargetEnum.prepend_if_ee('::EE::Types::TodoTargetEnum')

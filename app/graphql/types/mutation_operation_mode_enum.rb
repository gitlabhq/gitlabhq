# frozen_string_literal: true

module Types
  class MutationOperationModeEnum < BaseEnum
    graphql_name 'MutationOperationMode'
    description 'Different toggles for changing mutator behavior.'

    # Suggested param name for the enum: `operation_mode`

    value 'REPLACE', 'Performs a replace operation'
    value 'APPEND', 'Performs an append operation'
    value 'REMOVE', 'Performs a removal operation'
  end
end

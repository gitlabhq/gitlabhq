# frozen_string_literal: true

module Types
  class CommitActionModeEnum < BaseEnum
    graphql_name 'CommitActionMode'
    description 'Mode of a commit action'

    value 'CREATE', description: 'Create command.', value: :create
    value 'DELETE', description: 'Delete command.', value: :delete
    value 'MOVE', description: 'Move command.', value: :move
    value 'UPDATE', description: 'Update command.', value: :update
    value 'CHMOD', description: 'Chmod command.', value: :chmod
  end
end

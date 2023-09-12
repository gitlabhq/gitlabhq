# frozen_string_literal: true

module Types
  module WorkItems
    class AwardEmojiUpdateActionEnum < BaseEnum
      graphql_name 'WorkItemAwardEmojiUpdateAction'
      description 'Values for work item award emoji update enum'

      value 'ADD', 'Adds the emoji.', value: :add
      value 'REMOVE', 'Removes the emoji.', value: :remove
      value 'TOGGLE', 'Toggles the status of the emoji.', value: :toggle
    end
  end
end

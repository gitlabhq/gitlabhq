# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      class AwardEmojiUpdateInputType < BaseInputObject
        graphql_name 'WorkItemWidgetAwardEmojiUpdateInput'

        argument :action, ::Types::WorkItems::AwardEmojiUpdateActionEnum,
          required: true,
          description: 'Action for the update.'

        argument :name,
          GraphQL::Types::String,
          required: true,
          description: copy_field_description(Types::AwardEmojis::AwardEmojiType, :name)
      end
    end
  end
end

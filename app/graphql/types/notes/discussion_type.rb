# frozen_string_literal: true

module Types
  module Notes
    class DiscussionType < BaseObject
      graphql_name 'Discussion'

      authorize :read_note

      implements Types::Notes::BaseDiscussionInterface

      field :noteable, Types::NoteableType, null: true,
        description: 'Object which the discussion belongs to.'
      field :notes, Types::Notes::NoteType.connection_type, null: false,
        description: 'All notes in the discussion.'

      def noteable
        noteable = object.noteable

        return unless Ability.allowed?(context[:current_user], :"read_#{noteable.to_ability_name}", noteable)

        noteable
      end
    end
  end
end

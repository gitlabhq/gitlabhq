# frozen_string_literal: true

module Mutations
  module Todos
    class Snooze < ::Mutations::BaseMutation
      graphql_name 'TodoSnooze'

      authorize :update_todo
      authorize_granular_token permissions: :update_todo, boundary: :user, boundary_type: :user

      argument :id,
        ::Types::GlobalIDType[::Todo],
        required: true,
        description: 'Global ID of the to-do item to be snoozed.'

      argument :snooze_until,
        ::Types::TimeType,
        required: true,
        description: 'Time until which the todo should be snoozed.'

      field :todo, Types::TodoType,
        null: false,
        description: 'Requested to-do item.'

      def resolve(id:, snooze_until:)
        todo = authorized_find!(id: id)
        service_response = ::Todos::SnoozingService.new.snooze_todo(todo, snooze_until)

        {
          todo: todo,
          errors: service_response.errors
        }
      end
    end
  end
end

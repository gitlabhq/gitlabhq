# frozen_string_literal: true

module Mutations
  module Todos
    class UnSnooze < ::Mutations::BaseMutation
      graphql_name 'TodoUnSnooze'

      authorize :update_todo

      argument :id,
        ::Types::GlobalIDType[::Todo],
        required: true,
        description: 'Global ID of the to-do item to be snoozed.'

      field :todo, Types::TodoType,
        null: false,
        description: 'Requested to-do item.'

      def resolve(id:)
        todo = authorized_find!(id: id)
        service_response = ::Todos::SnoozingService.new.un_snooze_todo(todo)

        {
          todo: todo,
          errors: service_response.errors
        }
      end
    end
  end
end

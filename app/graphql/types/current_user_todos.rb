# frozen_string_literal: true

# Interface to expose todos for the current_user on the `object`
module Types
  module CurrentUserTodos
    include BaseInterface

    field_class Types::BaseField

    field :current_user_todos, Types::TodoType.connection_type,
          description: 'Todos for the current user',
          null: false do
            argument :state, Types::TodoStateEnum,
                     description: 'State of the todos',
                     required: false
          end

    def current_user_todos(state: nil)
      state ||= %i(done pending) # TodosFinder treats a `nil` state param as `pending`

      TodosFinder.new(current_user, state: state, type: object.class.name, target_id: object.id).execute
    end
  end
end

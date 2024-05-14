# frozen_string_literal: true

# Interface to expose todos for the current_user on the `object`
module Types
  module CurrentUserTodos
    include BaseInterface

    field_class Types::BaseField

    field :current_user_todos, Types::TodoType.connection_type,
      description: 'To-do items for the current user.',
      null: false do
      argument :state, Types::TodoStateEnum,
        description: 'State of the to-do items.',
        required: false
    end

    def current_user_todos(state: nil)
      state ||= %i[done pending] # TodosFinder treats a `nil` state param as `pending`
      target_type_name = unpresented.try(:todoable_target_type_name) || unpresented.class.name
      key = [state, target_type_name]

      BatchLoader::GraphQL.for(unpresented).batch(default_value: [], key: key) do |targets, loader, args|
        state, klass_name = args[:key]

        targets_by_id = targets.index_by(&:id)
        ids = targets_by_id.keys

        results = TodosFinder.new(current_user, state: state, type: klass_name, target_id: ids).execute

        by_target_id = results.group_by(&:target_id)

        by_target_id.each do |target_id, todos|
          target = targets_by_id[target_id]
          todos.each { _1.target = target } # prevent extra loads
          loader.call(target, todos)
        end
      end
    end
  end
end

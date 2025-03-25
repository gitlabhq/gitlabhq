# frozen_string_literal: true

module Todos
  module Delete
    class DoneTodosService < ::Todos::Destroy::BaseService
      extend ::Gitlab::Utils::Override

      MAX_UPDATE_AMOUNT = 100

      def execute(todos)
        todos_to_delete = todos.done.limit(MAX_UPDATE_AMOUNT) # we limit that in the service layer as well
        ids = todos_to_delete.ids # rubocop: disable CodeReuse/ActiveRecord -- we need ids to return from mutation

        todos_to_delete.delete_all

        ids
      end
    end
  end
end

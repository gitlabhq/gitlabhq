module API
  module V3
    class Todos < Grape::API
      before { authenticate! }

      resource :todos do
        desc 'Mark a todo as done' do
          success ::API::Entities::Todo
        end
        params do
          requires :id, type: Integer, desc: 'The ID of the todo being marked as done'
        end
        delete ':id' do
          todo = current_user.todos.find(params[:id])
          TodoService.new.mark_todos_as_done([todo], current_user)

          present todo.reload, with: ::API::Entities::Todo, current_user: current_user
        end

        desc 'Mark all todos as done'
        delete do
          todos = TodosFinder.new(current_user, params).execute
          TodoService.new.mark_todos_as_done(todos, current_user)
        end
      end
    end
  end
end

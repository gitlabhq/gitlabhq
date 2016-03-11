module API
  # Todos API
  class Todos < Grape::API
    before { authenticate! }

    resource :todos do
      helpers do
        def find_todos
          TodosFinder.new(current_user, params).execute
        end
      end

      # Get a todo list
      #
      # Example Request:
      #  GET /todos
      get do
        @todos = find_todos
        @todos = paginate @todos

        present @todos, with: Entities::Todo
      end

      # Mark todo as done
      #
      # Parameters:
      #   id: (required) - The ID of the todo being marked as done
      #
      # Example Request:
      #
      #  DELETE /todos/:id
      #
      delete ':id' do
        @todo = current_user.todos.find(params[:id])
        @todo.done

        present @todo, with: Entities::Todo
      end

      # Mark all todos as done
      #
      # Example Request:
      #
      #  DELETE /todos
      #
      delete do
        @todos = find_todos
        @todos.each(&:done)

        present @todos, with: Entities::Todo
      end
    end
  end
end

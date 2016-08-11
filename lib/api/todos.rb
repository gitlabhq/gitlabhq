module API
  # Todos API
  class Todos < Grape::API
    before { authenticate! }

    ISSUABLE_TYPES = {
      'merge_requests' => ->(id) { user_project.merge_requests.find(id) },
      'issues' => ->(id) { find_project_issue(id) }
    }

    resource :projects do
      ISSUABLE_TYPES.each do |type, finder|
        type_id_str = "#{type.singularize}_id".to_sym

        # Create a todo on an issuable
        #
        # Parameters:
        #   id (required) - The ID of a project
        #   issuable_id (required) - The ID of an issuable
        # Example Request:
        #   POST /projects/:id/issues/:issuable_id/todo
        #   POST /projects/:id/merge_requests/:issuable_id/todo
        post ":id/#{type}/:#{type_id_str}/todo" do
          issuable = instance_exec(params[type_id_str], &finder)
          todo = TodoService.new.mark_todo(issuable, current_user).first

          if todo
            present todo, with: Entities::Todo, current_user: current_user
          else
            not_modified!
          end
        end
      end
    end

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
      #
      get do
        todos = find_todos

        present paginate(todos), with: Entities::Todo, current_user: current_user
      end

      # Mark a todo as done
      #
      # Parameters:
      #   id: (required) - The ID of the todo being marked as done
      #
      # Example Request:
      #  DELETE /todos/:id
      #
      delete ':id' do
        todo = current_user.todos.find(params[:id])
        TodoService.new.mark_todos_as_done([todo], current_user)

        present todo.reload, with: Entities::Todo, current_user: current_user
      end

      # Mark all todos as done
      #
      # Example Request:
      #  DELETE /todos
      #
      delete do
        todos = find_todos
        TodoService.new.mark_todos_as_done(todos, current_user)
      end
    end
  end
end

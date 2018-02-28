module API
  class Todos < Grape::API
    include PaginationParams

    before { authenticate! }

    ISSUABLE_TYPES = {
      'merge_requests' => ->(iid) { find_merge_request_with_access(iid) },
      'issues' => ->(iid) { find_project_issue(iid) }
    }.freeze

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS  do
      ISSUABLE_TYPES.each do |type, finder|
        type_id_str = "#{type.singularize}_iid".to_sym

        desc 'Create a todo on an issuable' do
          success Entities::Todo
        end
        params do
          requires type_id_str, type: Integer, desc: 'The IID of an issuable'
        end
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

      desc 'Get a todo list' do
        success Entities::Todo
      end
      params do
        use :pagination
      end
      get do
        present paginate(find_todos), with: Entities::Todo, current_user: current_user
      end

      desc 'Mark a todo as done' do
        success Entities::Todo
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the todo being marked as done'
      end
      post ':id/mark_as_done' do
        TodoService.new.mark_todos_as_done_by_ids(params[:id], current_user)
        todo = current_user.todos.find(params[:id])

        present todo, with: Entities::Todo, current_user: current_user
      end

      desc 'Mark all todos as done'
      post '/mark_as_done' do
        todos = find_todos
        TodoService.new.mark_todos_as_done(todos, current_user)

        no_content!
      end
    end
  end
end

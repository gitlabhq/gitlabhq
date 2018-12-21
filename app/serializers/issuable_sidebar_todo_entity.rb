# frozen_string_literal: true

class IssuableSidebarTodoEntity < Grape::Entity
  include Gitlab::Routing

  expose :id

  expose :delete_path do |todo|
    dashboard_todo_path(todo) if todo
  end
end

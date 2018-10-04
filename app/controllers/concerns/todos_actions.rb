# frozen_string_literal: true

module TodosActions
  extend ActiveSupport::Concern

  def create
    todo = TodoService.new.mark_todo(issuable, current_user)

    render json: {
      count: TodosFinder.new(current_user, state: :pending).execute.count,
      delete_path: dashboard_todo_path(todo)
    }
  end
end

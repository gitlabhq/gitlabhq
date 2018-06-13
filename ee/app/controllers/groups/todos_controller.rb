class Groups::TodosController < Groups::ApplicationController
  include Gitlab::Utils::StrongMemoize

  before_action :authenticate_user!, only: [:create]

  def create
    todo = TodoService.new.mark_todo(epic, current_user)

    render json: {
      count: TodosFinder.new(current_user, state: :pending).execute.count,
      delete_path: dashboard_todo_path(todo)
    }
  end

  private

  def epic
    strong_memoize(:epic) do
      case params[:issuable_type]
      when "epic"
        @group.epics.find_by(id: params[:issuable_id])
      end
    end
  end
end

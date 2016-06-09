class Projects::TodosController < Projects::ApplicationController
  def create
    TodoService.new.mark_todo(issuable, current_user)

    render json: {
      todo: current_user.todos.find_by(state: :pending, action: Todo::MARKED, target_id: issuable.id),
      count: current_user.todos.pending.count,
    }
  end

  def update
    current_user.todos.find_by_id(params[:id]).update(state: :done)

    render json: {
      count: current_user.todos.pending.count,
    }
  end

  private

  def issuable
    @issuable ||= begin
      case params[:issuable_type]
      when "issue"
        @project.issues.find(params[:issuable_id])
      when "merge_request"
        @project.merge_requests.find(params[:issuable_id])
      end
    end
  end
end

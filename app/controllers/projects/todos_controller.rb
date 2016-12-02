class Projects::TodosController < Projects::ApplicationController
  before_action :authenticate_user!, only: [:create]

  def create
    todo = TodoService.new.mark_todo(issuable, current_user)

    render json: {
      count: TodosFinder.new(current_user, state: :pending).execute.count,
      delete_path: dashboard_todo_path(todo)
    }
  end

  private

  def issuable
    @issuable ||= begin
      case params[:issuable_type]
      when "issue"
        IssuesFinder.new(current_user, project_id: @project.id).find(params[:issuable_id])
      when "merge_request"
        @project.merge_requests.find(params[:issuable_id])
      end
    end
  end
end

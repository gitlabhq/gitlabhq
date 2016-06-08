class Projects::TodosController < Projects::ApplicationController
  def create
    json_data = Hash.new

    if params[:todo_id].nil?
      TodoService.new.mark_todo(issuable, current_user)

      json_data[:todo] = current_user.todos.find_by(state: :pending, action: Todo::MARKED, target_id: issuable.id)
    else
      current_user.todos.find_by_id(params[:todo_id]).update(state: :done)
    end

    render json: json_data.merge({ count: current_user.todos.pending.count })
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

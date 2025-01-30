# frozen_string_literal: true

class Dashboard::TodosController < Dashboard::ApplicationController
  feature_category :notifications
  urgency :low

  def index
    push_frontend_feature_flag(:todos_bulk_actions, current_user)
  end

  def destroy
    todo = current_user.todos.find(params[:id])

    TodoService.new.resolve_todo(todo, current_user, resolved_by_action: :mark_done)

    respond_to do |format|
      format.html do
        redirect_to dashboard_todos_path, status: :found, notice: _('To-do item successfully marked as done.')
      end
      format.js { head :ok }
      format.json { render json: todos_counts }
    end
  end

  private

  def todos_counts
    {
      count: current_user.todos_pending_count,
      done_count: current_user.todos_done_count
    }
  end
end

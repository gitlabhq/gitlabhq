class Dashboard::TodosController < Dashboard::ApplicationController
  before_action :find_todos, only: [:index, :destroy_all]

  def index
    @todos = @todos.page(params[:page])
  end

  def destroy
    TodoService.new.mark_todos_as_done([todo], current_user)

    respond_to do |format|
      format.html { redirect_to dashboard_todos_path, notice: 'Todo was successfully marked as done.' }
      format.js { head :ok }
      format.json { render json: todos_counts }
    end
  end

  def destroy_all
    TodoService.new.mark_todos_as_done(@todos, current_user)

    respond_to do |format|
      format.html { redirect_to dashboard_todos_path, notice: 'All todos were marked as done.' }
      format.js { head :ok }
      format.json { render json: todos_counts }
    end
  end

  private

  def todo
    @todo ||= find_todos.find(params[:id])
  end

  def find_todos
    @todos ||= TodosFinder.new(current_user, params).execute
  end

  def todos_counts
    {
      count: current_user.todos_pending_count,
      done_count: current_user.todos_done_count
    }
  end
end

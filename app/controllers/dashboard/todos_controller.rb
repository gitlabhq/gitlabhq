class Dashboard::TodosController < Dashboard::ApplicationController
  include ActionView::Helpers::NumberHelper

  before_action :find_todos, only: [:index, :destroy_all]

  def index
    @sort = params[:sort]
    @todos = @todos.page(params[:page])
    if @todos.out_of_range? && @todos.total_pages != 0
      redirect_to url_for(params.merge(page: @todos.total_pages))
    end
  end

  def destroy
    TodoService.new.mark_todos_as_done_by_ids([params[:id]], current_user)

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

  def restore
    TodoService.new.mark_todos_as_pending_by_ids([params[:id]], current_user)

    render json: todos_counts
  end

  # Used in TodosHelper also
  def self.todos_count_format(count)
    count >= 100 ? '99+' : count
  end

  private

  def find_todos
    @todos ||= TodosFinder.new(current_user, params).execute
  end

  def todos_counts
    {
      count: number_with_delimiter(current_user.todos_pending_count),
      done_count: number_with_delimiter(current_user.todos_done_count)
    }
  end
end

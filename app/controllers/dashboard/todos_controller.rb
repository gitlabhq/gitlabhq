class Dashboard::TodosController < Dashboard::ApplicationController
  include ActionView::Helpers::NumberHelper

  before_action :authorize_read_project!, only: :index
  before_action :find_todos, only: [:index, :destroy_all]

  def index
    @sort = params[:sort]
    @todos = @todos.page(params[:page])

    return if redirect_out_of_range(@todos)
  end

  def destroy
    TodoService.new.mark_todos_as_done_by_ids(params[:id], current_user)

    respond_to do |format|
      format.html do
        redirect_to dashboard_todos_path,
                    status: 302,
                    notice: 'Todo was successfully marked as done.'
      end
      format.js { head :ok }
      format.json { render json: todos_counts }
    end
  end

  def destroy_all
    updated_ids = TodoService.new.mark_todos_as_done(@todos, current_user)

    respond_to do |format|
      format.html { redirect_to dashboard_todos_path, status: 302, notice: 'All todos were marked as done.' }
      format.js { head :ok }
      format.json { render json: todos_counts.merge(updated_ids: updated_ids) }
    end
  end

  def restore
    TodoService.new.mark_todos_as_pending_by_ids(params[:id], current_user)

    render json: todos_counts
  end

  def bulk_restore
    TodoService.new.mark_todos_as_pending_by_ids(params[:ids], current_user)

    render json: todos_counts
  end

  private

  def authorize_read_project!
    project_id = params[:project_id]

    if project_id.present?
      project = Project.find(project_id)
      render_404 unless can?(current_user, :read_project, project)
    end
  end

  def find_todos
    @todos ||= TodosFinder.new(current_user, todo_params).execute
  end

  def todos_counts
    {
      count: number_with_delimiter(current_user.todos_pending_count),
      done_count: number_with_delimiter(current_user.todos_done_count)
    }
  end

  def todo_params
    params.permit(:action_id, :author_id, :project_id, :type, :sort, :state)
  end

  def redirect_out_of_range(todos)
    total_pages =
      if todo_params.except(:sort, :page).empty?
        (current_user.todos_pending_count.to_f / todos.limit_value).ceil
      else
        todos.total_pages
      end

    return false if total_pages.zero?

    out_of_range = todos.current_page > total_pages

    if out_of_range
      redirect_to url_for(safe_params.merge(page: total_pages, only_path: true))
    end

    out_of_range
  end
end

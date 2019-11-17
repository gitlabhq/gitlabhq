# frozen_string_literal: true

class Dashboard::TodosController < Dashboard::ApplicationController
  include ActionView::Helpers::NumberHelper
  include PaginatedCollection

  before_action :authorize_read_project!, only: :index
  before_action :authorize_read_group!, only: :index
  before_action :find_todos, only: [:index, :destroy_all]

  def index
    @sort = params[:sort]
    @todos = @todos.page(params[:page])
    @todos = @todos.with_entity_associations

    return if redirect_out_of_range(@todos, todos_page_count(@todos))
  end

  def destroy
    TodoService.new.mark_todos_as_done_by_ids(params[:id], current_user)

    respond_to do |format|
      format.html do
        redirect_to dashboard_todos_path,
                    status: :found,
                    notice: _('To-do item successfully marked as done.')
      end
      format.js { head :ok }
      format.json { render json: todos_counts }
    end
  end

  def destroy_all
    updated_ids = TodoService.new.mark_todos_as_done(@todos, current_user)

    respond_to do |format|
      format.html { redirect_to dashboard_todos_path, status: :found, notice: _('Everything on your to-do list is marked as done.') }
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

  def authorize_read_group!
    group_id = params[:group_id]

    if group_id.present?
      group = Group.find(group_id)
      render_404 unless can?(current_user, :read_group, group)
    end
  end

  def find_todos
    @todos ||= TodosFinder.new(current_user, todo_params).execute
  end

  def todos_counts
    {
      count: current_user.todos_pending_count,
      done_count: current_user.todos_done_count
    }
  end

  def todos_page_count(todos)
    if todo_params.except(:sort, :page).empty?
      (current_user.todos_pending_count.to_f / todos.limit_value).ceil
    else
      todos.total_pages
    end
  end

  def todo_params
    params.permit(:action_id, :author_id, :project_id, :type, :sort, :state, :group_id)
  end
end

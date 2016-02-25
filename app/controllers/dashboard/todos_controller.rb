class Dashboard::TodosController < Dashboard::ApplicationController
  before_action :find_todos, only: [:index, :destroy_all]

  def index
    @todos = @todos.page(params[:page]).per(PER_PAGE)
  end

  def destroy
    todo.done!

    respond_to do |format|
      format.html { redirect_to dashboard_todos_path, notice: 'Todo was successfully marked as done.' }
      format.js { render nothing: true }
    end
  end

  def destroy_all
    @todos.each(&:done!)

    respond_to do |format|
      format.html { redirect_to dashboard_todos_path, notice: 'All todos were marked as done.' }
      format.js { render nothing: true }
    end
  end

  private

  def todo
    @todo ||= current_user.todos.find(params[:id])
  end

  def find_todos
    @todos = TodosFinder.new(current_user, params).execute
  end
end

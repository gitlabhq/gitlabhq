class Dashboard::TodosController < Dashboard::ApplicationController
  def index
    @todos = TodosFinder.new(current_user, params).execute
    @todos = @todos.page(params[:page]).per(PER_PAGE)
  end

  def destroy
    todo.done!

    respond_to do |format|
      format.html { redirect_to dashboard_todos_path, notice: 'Todo was successfully marked as done.' }
      format.js { render nothing: true }
    end
  end

  private

  def todo
    @todo ||= current_user.todos.find(params[:id])
  end
end

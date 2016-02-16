class Dashboard::TasksController < Dashboard::ApplicationController
  def index
    @tasks = case params[:state]
      when 'done'
        current_user.tasks.done
      else
        current_user.tasks.pending
      end

    @tasks = @tasks.page(params[:page]).per(PER_PAGE)
  end

  def destroy
    task.done!

    respond_to do |format|
      format.html { redirect_to dashboard_tasks_path, notice: 'Task was successfully marked as done.' }
      format.js { render nothing: true }
    end
  end

  private

  def task
    @task ||= current_user.tasks.find(params[:id])
  end
end

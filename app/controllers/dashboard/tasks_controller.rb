class Dashboard::TasksController < Dashboard::ApplicationController
  def index
    @tasks = case params[:state]
      when 'done'
        current_user.tasks.done
      else
        current_user.tasks.pending
      end

    @tasks = @tasks.page(params[:page]).per(PER_PAGE)

    @pending_count = current_user.tasks.pending.count
    @done_count = current_user.tasks.done.count
  end
end

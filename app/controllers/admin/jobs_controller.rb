class Admin::JobsController < Admin::ApplicationController
  def index
    @scope = params[:scope]
    @all_builds = Ci::Build
    @builds = @all_builds.order('created_at DESC')
    @builds =
      case @scope
      when 'pending'
        @builds.pending.reverse_order
      when 'running'
        @builds.running.reverse_order
      when 'finished'
        @builds.finished
      else
        @builds
      end
    @builds = @builds.page(params[:page]).per(30)
  end

  def cancel_all
    Ci::Build.running_or_pending.each(&:cancel)

    redirect_to admin_jobs_path, status: 303
  end
end

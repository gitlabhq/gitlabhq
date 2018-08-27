class Admin::JobsController < Admin::ApplicationController
  # rubocop: disable CodeReuse/ActiveRecord
  def index
    @scope = params[:scope]
    @all_builds = Ci::Build
    @builds = @all_builds.order('id DESC')
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
  # rubocop: enable CodeReuse/ActiveRecord

  def cancel_all
    Ci::Build.running_or_pending.each(&:cancel)

    redirect_to admin_jobs_path, status: :see_other
  end
end

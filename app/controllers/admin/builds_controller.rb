class Admin::BuildsController < Admin::ApplicationController
  def index
    @scope = params[:scope]
    @all_builds = Ci::Build
    @builds = @all_builds.order('created_at DESC')
    @builds =
      case @scope
      when 'all'
        @builds
      when 'finished'
        @builds.finished
      else
        @builds.running_or_pending.reverse_order
      end
    @builds = @builds.page(params[:page]).per(30)
  end

  def cancel_all
    Ci::Build.running_or_pending.each(&:cancel)

    redirect_to admin_builds_path
  end
end

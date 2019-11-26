# frozen_string_literal: true

class Admin::JobsController < Admin::ApplicationController
  def index
    # We need all builds for tabs counters
    @all_builds = JobsFinder.new(current_user: current_user).execute

    @scope = params[:scope]
    @builds = JobsFinder.new(current_user: current_user, params: params).execute
    @builds = @builds.eager_load_everything
    @builds = @builds.page(params[:page]).per(30)
  end

  def cancel_all
    Ci::Build.running_or_pending.each(&:cancel)

    redirect_to admin_jobs_path, status: :see_other
  end
end

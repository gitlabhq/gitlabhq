class Projects::PathLocksController < Projects::ApplicationController
  include PathLocksHelper

  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_push_code!, only: [:toggle]

  before_action :check_license

  def index
    @path_locks = @project.path_locks.page(params[:page])
  end

  def toggle
    path_lock = @project.path_locks.find_by(path: params[:path])

    if path_lock
      PathLocks::UnlockService.new(project, current_user).execute(path_lock)
    else
      PathLocks::LockService.new(project, current_user).execute(params[:path])
    end

    head :ok
  rescue PathLocks::UnlockService::AccessDenied, PathLocks::LockService::AccessDenied
    return access_denied!
  end

  def destroy
    path_lock = @project.path_locks.find(params[:id])

    begin
      PathLocks::UnlockService.new(project, current_user).execute(path_lock)
    rescue PathLocks::UnlockService::AccessDenied
      return access_denied!
    end

    respond_to do |format|
      format.html do
        redirect_to namespace_project_locks_path(@project.namespace, @project)
      end
      format.js
    end
  end

  private

  def check_license
    unless license_allows_file_locks?
      flash[:alert] = 'You need a different license to enable FileLocks feature'
      redirect_to admin_license_path
    end
  end
end

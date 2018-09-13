class Projects::PathLocksController < Projects::ApplicationController
  include PathLocksHelper
  include ExtractsPath

  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_push_code!, only: [:toggle]

  before_action :check_license
  before_action :assign_ref_vars, only: :toggle
  before_action :lfs_blob_ids, only: :toggle

  def index
    @path_locks = @project.path_locks.page(params[:page])
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def toggle
    path_lock = @project.path_locks.find_by(path: params[:path])

    if path_lock
      unlock_file(path_lock)
    else
      lock_file
    end

    head :ok
  rescue PathLocks::UnlockService::AccessDenied, PathLocks::LockService::AccessDenied
    access_denied!
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def destroy
    path_lock = @project.path_locks.find(params[:id])

    begin
      PathLocks::UnlockService.new(project, current_user).execute(path_lock)
    rescue PathLocks::UnlockService::AccessDenied
      return access_denied!
    end

    respond_to do |format|
      format.html do
        redirect_to project_locks_path(@project), status: :found
      end
      format.js
    end
  end

  private

  def check_license
    unless @project.feature_available?(:file_locks)
      flash[:alert] = _('You need a different license to enable FileLocks feature')
      redirect_to admin_license_path
    end
  end

  def lock_file
    path_lock = PathLocks::LockService.new(project, current_user).execute(params[:path])

    if path_lock.persisted? && sync_with_lfs?
      Lfs::LockFileService.new(
        project,
        current_user,
        path: params[:path],
        create_path_lock: false
      ).execute
    end
  end

  def unlock_file(path_lock)
    PathLocks::UnlockService.new(project, current_user).execute(path_lock)

    if sync_with_lfs?
      Lfs::UnlockFileService.new(project, current_user, path: path_lock.path, force: true).execute
    end
  end

  # Override get_id from ExtractsPath.
  # We don't support file locking per branch, that's why we use the root branch.
  def get_id
    id = project.repository.root_ref
    id += "/#{params[:path]}" if params[:path].present?
    id
  end

  def lfs_file?
    blob = project.repository.blob_at_branch(@ref, @path)

    return false unless blob

    @lfs_blob_ids.include?(blob.id)
  end

  def sync_with_lfs?
    project.lfs_enabled? && lfs_file?
  end
end

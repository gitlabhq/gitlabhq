module PathLocksHelper
  def can_unlock?(path_lock, current_user = @current_user, project = @project)
    can?(current_user, :admin_path_locks, project) || path_lock.user == current_user
  end

  def license_allows_file_locks?
    ::License.current && ::License.current.add_on?('GitLab_FileLocks')
  end
end

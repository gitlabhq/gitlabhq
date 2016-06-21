module PathLocksHelper
  def can_unlock?(path_lock, current_user = @current_user)
    can?(current_user, :admin_locks, path_lock) || path_lock.user == current_user
  end

  def license_allows_file_locks?
    ::License.current && ::License.current.add_on?('GitLab_FileLocks')
  end
end

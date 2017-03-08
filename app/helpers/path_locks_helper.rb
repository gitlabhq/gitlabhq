module PathLocksHelper
  def can_unlock?(path_lock, current_user = @current_user, project = @project)
    can?(current_user, :admin_path_locks, project) || path_lock.user == current_user
  end

  def license_allows_file_locks?
    @license_allows_file_locks ||= (::License.current && ::License.current.add_on?('GitLab_FileLocks'))
  end

  def text_label_for_lock(file_lock, path)
    if file_lock.path == path
      "Locked by #{file_lock.user.name}"
    else
      # Nested lock
      "#{file_lock.user.name} has a lock on \"#{file_lock.path}\""
    end
  end
end

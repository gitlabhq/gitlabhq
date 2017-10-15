module RepositoryMirroring
  def storage_path
    @project.repository_storage_path
  end

  def push_remote_branches(remote, branches)
    gitlab_shell.push_remote_branches(storage_path, disk_path, remote, branches)
  end

  def delete_remote_branches(remote, branches)
    gitlab_shell.delete_remote_branches(storage_path, disk_path, remote, branches)
  end
end

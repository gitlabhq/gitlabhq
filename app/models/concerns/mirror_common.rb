module MirrorCommon
  # TODO: Refactor in EE
  def set_remote_as_mirror(name)
    config = raw_repository.rugged.config

    # This is used by Gitlab Geo to define repository as equivalent as "git clone --mirror"
    config["remote.#{name}.fetch"] = 'refs/*:refs/*'
    config["remote.#{name}.mirror"] = true
    config["remote.#{name}.prune"] = true
  end

  def fetch_remote(remote, forced: false, no_tags: false)
    gitlab_shell.fetch_remote(storage_path, path_with_namespace, remote, forced: forced, no_tags: no_tags)
  end
end

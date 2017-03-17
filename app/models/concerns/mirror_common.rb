module MirrorCommon
  # TODO: Refactor in EE
  def storage_path
    @project.repository_storage_path
  end

  def add_remote(name, url)
    raw_repository.remote_add(name, url)
  rescue Rugged::ConfigError
    raw_repository.remote_update(name, url: url)
  end

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

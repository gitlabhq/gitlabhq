module RepositoryMirroring
  IMPORT_HEAD_REFS = '+refs/heads/*:refs/heads/*'.freeze
  IMPORT_TAG_REFS = '+refs/tags/*:refs/tags/*'.freeze

  def set_remote_as_mirror(name)
    # This is used to define repository as equivalent as "git clone --mirror"
    raw_repository.rugged.config["remote.#{name}.fetch"] = 'refs/*:refs/*'
    raw_repository.rugged.config["remote.#{name}.mirror"] = true
    raw_repository.rugged.config["remote.#{name}.prune"] = true
  end

  def set_import_remote_as_mirror(remote_name)
    # Add first fetch with Rugged so it does not create its own.
    raw_repository.rugged.config["remote.#{remote_name}.fetch"] = IMPORT_HEAD_REFS

    add_remote_fetch_config(remote_name, IMPORT_TAG_REFS)

    raw_repository.rugged.config["remote.#{remote_name}.mirror"] = true
    raw_repository.rugged.config["remote.#{remote_name}.prune"] = true
  end

  def add_remote_fetch_config(remote_name, refspec)
    run_git(%W[config --add remote.#{remote_name}.fetch #{refspec}])
  end

  def fetch_mirror(remote, url)
    add_remote(remote, url)
    set_remote_as_mirror(remote)
    fetch_remote(remote, forced: true)
    remove_remote(remote)
  end
end

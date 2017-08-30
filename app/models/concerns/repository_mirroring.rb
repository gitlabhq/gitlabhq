module RepositoryMirroring
  IMPORT_REFS = %w[+refs/pull/*/head:refs/merge-requests/*/head +refs/heads/*:refs/heads/* +refs/tags/*:refs/tags/*].freeze

  def set_remote_as_mirror(name)
    # This is used to define repository as equivalent as "git clone --mirror"
    config["remote.#{name}.fetch"] = 'refs/*:refs/*'
    config["remote.#{name}.mirror"] = true
    config["remote.#{name}.prune"] = true
  end

  def set_import_remote_as_mirror(name)
    # Add first fetch with Rugged so it does not create its own.
    config["remote.#{name}.fetch"] = IMPORT_REFS.first

    IMPORT_REFS.drop(1).each do |ref|
      run_git(%W[config --add remote.#{name}.fetch #{ref}])
    end

    config["remote.#{name}.mirror"] = true
    config["remote.#{name}.prune"] = true
  rescue Rugged::ConfigError
    # Ignore multivar errors when the config already exist
    # TODO: refactor/fix this
  end

  def fetch_mirror(remote, url)
    add_remote(remote, url)
    set_remote_as_mirror(remote)
    fetch_remote(remote, forced: true)
    remove_remote(remote)
  end

  def config
    raw_repository.rugged.config
  end
end

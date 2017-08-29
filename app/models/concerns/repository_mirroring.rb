module RepositoryMirroring
  GITHUB_REFS = %w[+refs/pull/*/head:refs/merge-requests/*/head +refs/heads/*:refs/heads/* +refs/tags/*:refs/tags/*].freeze

  def set_remote_as_mirror(name)
    config = raw_repository.rugged.config

    # This is used to define repository as equivalent as "git clone --mirror"
    config["remote.#{name}.fetch"] = 'refs/*:refs/*'
    config["remote.#{name}.mirror"] = true
    config["remote.#{name}.prune"] = true
  end

  def fetch_github_refs
    # This is used to define repository as equivalent as "git clone --mirror"
    GITHUB_REFS.each do |ref|
      fetch_ref(path, *ref.split(':'))
    end
  end

  def fetch_mirror(remote, url)
    add_remote(remote, url)
    set_remote_as_mirror(remote)
    fetch_remote(remote, forced: true)
    remove_remote(remote)
  end
end

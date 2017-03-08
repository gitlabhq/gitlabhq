module RepositoryMirroring
  def storage_path
    @project.repository_storage_path
  end

  def push_remote_branches(remote, branches)
    gitlab_shell.push_remote_branches(storage_path, path_with_namespace, remote, branches)
  end

  def delete_remote_branches(remote, branches)
    gitlab_shell.delete_remote_branches(storage_path, path_with_namespace, remote, branches)
  end

  def add_remote(name, url)
    raw_repository.remote_add(name, url)
  rescue Rugged::ConfigError
    raw_repository.remote_update(name, url: url)
  end

  def remove_remote(name)
    raw_repository.remote_delete(name)
    true
  rescue Rugged::ConfigError
    false
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

  def remote_tags(remote)
    gitlab_shell.list_remote_tags(storage_path, path_with_namespace, remote).map do |name, target|
      Gitlab::Git::Tag.new(raw_repository, name, target)
    end
  end

  def remote_branches(remote_name)
    branches = []

    rugged.references.each("refs/remotes/#{remote_name}/*").map do |ref|
      name = ref.name.sub(/\Arefs\/remotes\/#{remote_name}\//, '')

      begin
        branches << Gitlab::Git::Branch.new(raw_repository, name, ref.target)
      rescue Rugged::ReferenceError
        # Omit invalid branch
      end
    end

    branches
  end
end

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

  def set_remote_as_mirror(name)
    config = raw_repository.rugged.config

    # This is used to define repository as equivalent as "git clone --mirror"
    config["remote.#{name}.fetch"] = 'refs/*:refs/*'
    config["remote.#{name}.mirror"] = true
    config["remote.#{name}.prune"] = true
  end

  def fetch_mirror(remote, url)
    add_remote(remote, url)
    set_remote_as_mirror(remote)
    fetch_remote(remote, forced: true)
    remove_remote(remote)
  end

  def remote_tags(remote)
    gitlab_shell.list_remote_tags(storage_path, path_with_namespace, remote).map do |name, target|
      target_commit = Gitlab::Git::Commit.find(raw_repository, target)
      Gitlab::Git::Tag.new(raw_repository, name, target, target_commit)
    end
  end

  def remote_branches(remote_name)
    branches = []

    rugged.references.each("refs/remotes/#{remote_name}/*").map do |ref|
      name = ref.name.sub(/\Arefs\/remotes\/#{remote_name}\//, '')

      begin
        target_commit = Gitlab::Git::Commit.find(raw_repository, ref.target)
        branches << Gitlab::Git::Branch.new(raw_repository, name, ref.target, target_commit)
      rescue Rugged::ReferenceError
        # Omit invalid branch
      end
    end

    branches
  end
end

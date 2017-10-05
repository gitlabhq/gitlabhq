module RepositoryMirroring
<<<<<<< HEAD
  def storage_path
    @project.repository_storage_path
  end

  def push_remote_branches(remote, branches)
    gitlab_shell.push_remote_branches(storage_path, disk_path, remote, branches)
  end

  def delete_remote_branches(remote, branches)
    gitlab_shell.delete_remote_branches(storage_path, disk_path, remote, branches)
  end

  def set_remote_as_mirror(name)
    config = raw_repository.rugged.config
=======
  IMPORT_HEAD_REFS = '+refs/heads/*:refs/heads/*'.freeze
  IMPORT_TAG_REFS = '+refs/tags/*:refs/tags/*'.freeze
>>>>>>> ce/master

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

  def remote_tags(remote)
    gitlab_shell.list_remote_tags(storage_path, disk_path, remote).map do |name, target|
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

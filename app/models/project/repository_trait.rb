module Project::RepositoryTrait
  as_trait do
    def valid_repo?
      repo
    rescue
      errors.add(:path, "Invalid repository path")
      false
    end

    def commit(commit_id = nil)
      Commit.find_or_first(repo, commit_id, root_ref)
    end

    def fresh_commits(n = 10)
      Commit.fresh_commits(repo, n)
    end

    def commits_with_refs(n = 20)
      Commit.commits_with_refs(repo, n)
    end

    def commits_since(date)
      Commit.commits_since(repo, date)
    end

    def commits(ref, path = nil, limit = nil, offset = nil)
      Commit.commits(repo, ref, path, limit, offset)
    end

    def commits_between(from, to)
      Commit.commits_between(repo, from, to)
    end

    def write_hooks
      %w(post-receive).each do |hook|
        write_hook(hook, File.read(File.join(Rails.root, 'lib', "#{hook}-hook")))
      end
    end

    def satellite
      @satellite ||= Gitlab::Satellite.new(self)
    end

    def write_hook(name, content)
      hook_file = File.join(path_to_repo, 'hooks', name)

      File.open(hook_file, 'w') do |f|
        f.write(content)
      end

      File.chmod(0775, hook_file)
    end

    def has_post_receive_file?
      hook_file = File.join(path_to_repo, 'hooks', 'post-receive')
      File.exists?(hook_file) 
    end

    def tags
      repo.tags.map(&:name).sort.reverse
    end

    def repo
      @repo ||= Grit::Repo.new(path_to_repo)
    end

    def url_to_repo
      Gitlab::GitHost.url_to_repo(path)
    end

    def path_to_repo
      File.join(GIT_HOST["base_path"], "#{path}.git")
    end

    def update_repository
      Gitlab::GitHost.system.update_project(path, self)

      write_hooks if File.exists?(path_to_repo)
    end

    def destroy_repository
      Gitlab::GitHost.system.destroy_project(self)
    end

    def repo_exists?
      @repo_exists ||= (repo && !repo.branches.empty?)
    rescue 
      @repo_exists = false
    end

    def heads
      @heads ||= repo.heads
    end

    def tree(fcommit, path = nil)
      fcommit = commit if fcommit == :head
      tree = fcommit.tree
      path ? (tree / path) : tree
    end

    def open_branches
      if protected_branches.empty?
        self.repo.heads
      else
        pnames = protected_branches.map(&:name)
        self.repo.heads.reject { |h| pnames.include?(h.name) }
      end.sort_by(&:name)
    end

    def has_commits?
      !!commit
    end

    def root_ref 
      default_branch || "master"
    end
  end
end

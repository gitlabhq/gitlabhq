class Repository
  # Repository directory name with namespace direcotry
  # Examples:
  #   gitlab/gitolite
  #   diaspora
  #
  attr_accessor :path_with_namespace

  # Grit repo object
  attr_accessor :repo

  # Default branch in the repository
  attr_accessor :root_ref

  def initialize(path_with_namespace, root_ref = 'master')
    @root_ref = root_ref || "master"
    @path_with_namespace = path_with_namespace

    # Init grit repo object
    repo
  end

  def raw
    repo
  end

  def path_to_repo
    @path_to_repo ||= File.join(Gitlab.config.gitolite.repos_path, "#{path_with_namespace}.git")
  end

  def repo
    @repo ||= Grit::Repo.new(path_to_repo)
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

  def last_commit_for(ref, path = nil)
    commits(ref, path, 1).first
  end

  def commits_between(from, to)
    Commit.commits_between(repo, from, to)
  end

  def has_post_receive_file?
    !!hook_file
  end

  def valid_post_receive_file?
    valid_hook_file == hook_file
  end

  def valid_hook_file
    @valid_hook_file ||= File.read(Rails.root.join('lib', 'hooks', 'post-receive'))
  end

  def hook_file
    @hook_file ||= begin
                     hook_path = File.join(path_to_repo, 'hooks', 'post-receive')
                     File.read(hook_path) if File.exists?(hook_path)
                   end
  end

  # Returns an Array of branch names
  def branch_names
    repo.branches.collect(&:name).sort
  end

  # Returns an Array of Branches
  def branches
    repo.branches.sort_by(&:name)
  end

  # Returns an Array of tag names
  def tag_names
    repo.tags.collect(&:name).sort.reverse
  end

  # Returns an Array of Tags
  def tags
    repo.tags.sort_by(&:name).reverse
  end

  # Returns an Array of branch and tag names
  def ref_names
    [branch_names + tag_names].flatten
  end

  def heads
    @heads ||= repo.heads
  end

  def tree(fcommit, path = nil)
    fcommit = commit if fcommit == :head
    tree = fcommit.tree
    path ? (tree / path) : tree
  end

  def has_commits?
    !!commit
  rescue Grit::NoSuchPathError
    false
  end

  def empty?
    !has_commits?
  end

  # Discovers the default branch based on the repository's available branches
  #
  # - If no branches are present, returns nil
  # - If one branch is present, returns its name
  # - If two or more branches are present, returns the one that has a name
  #   matching root_ref (default_branch or 'master' if default_branch is nil)
  def discover_default_branch
    if branch_names.length == 0
      nil
    elsif branch_names.length == 1
      branch_names.first
    else
      branch_names.select { |v| v == root_ref }.first
    end
  end

  # Archive Project to .tar.gz
  #
  # Already packed repo archives stored at
  # app_root/tmp/repositories/project_name/project_name-commit-id.tag.gz
  #
  def archive_repo(ref)
    ref = ref || self.root_ref
    commit = self.commit(ref)
    return nil unless commit

    # Build file path
    file_name = self.path_with_namespace.gsub("/","_") + "-" + commit.id.to_s + ".tar.gz"
    storage_path = Rails.root.join("tmp", "repositories")
    file_path = File.join(storage_path, self.path_with_namespace, file_name)

    # Put files into a directory before archiving
    prefix = self.path_with_namespace + "/"

    # Create file if not exists
    unless File.exists?(file_path)
      FileUtils.mkdir_p File.dirname(file_path)
      file = self.repo.archive_to_file(ref, prefix,  file_path)
    end

    file_path
  end
end

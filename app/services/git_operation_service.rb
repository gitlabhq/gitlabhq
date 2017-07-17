class GitOperationService
  attr_reader :user, :repository

  def initialize(new_user, new_repository)
    @user = new_user
    @repository = new_repository
  end

  def add_branch(branch_name, newrev)
    ref = Gitlab::Git::BRANCH_REF_PREFIX + branch_name
    oldrev = Gitlab::Git::BLANK_SHA

    update_ref_in_hooks(ref, newrev, oldrev)
  end

  def rm_branch(branch)
    ref = Gitlab::Git::BRANCH_REF_PREFIX + branch.name
    oldrev = branch.target
    newrev = Gitlab::Git::BLANK_SHA

    update_ref_in_hooks(ref, newrev, oldrev)
  end

  def add_tag(tag_name, newrev, options = {})
    ref = Gitlab::Git::TAG_REF_PREFIX + tag_name
    oldrev = Gitlab::Git::BLANK_SHA

    with_hooks(ref, newrev, oldrev) do |service|
      # We want to pass the OID of the tag object to the hooks. For an
      # annotated tag we don't know that OID until after the tag object
      # (raw_tag) is created in the repository. That is why we have to
      # update the value after creating the tag object. Only the
      # "post-receive" hook will receive the correct value in this case.
      raw_tag = repository.rugged.tags.create(tag_name, newrev, options)
      service.newrev = raw_tag.target_id
    end
  end

  def rm_tag(tag)
    ref = Gitlab::Git::TAG_REF_PREFIX + tag.name
    oldrev = tag.target
    newrev = Gitlab::Git::BLANK_SHA

    update_ref_in_hooks(ref, newrev, oldrev) do
      repository.rugged.tags.delete(tag_name)
    end
  end

  # Whenever `start_branch_name` is passed, if `branch_name` doesn't exist,
  # it would be created from `start_branch_name`.
  # If `start_project` is passed, and the branch doesn't exist,
  # it would try to find the commits from it instead of current repository.
  def with_branch(
    branch_name,
    start_branch_name: nil,
    start_project: repository.project,
    &block)

    start_repository = start_project.repository
    start_branch_name = nil if start_repository.empty_repo?

    if start_branch_name && !start_repository.branch_exists?(start_branch_name)
      raise ArgumentError, "Cannot find branch #{start_branch_name} in #{start_repository.path_with_namespace}"
    end

    update_branch_with_hooks(branch_name) do
      repository.with_repo_branch_commit(
        start_repository,
        start_branch_name || branch_name,
        &block)
    end
  end

  private

  def update_branch_with_hooks(branch_name)
    update_autocrlf_option

    was_empty = repository.empty?

    # Make commit
    newrev = yield

    unless newrev
      raise Repository::CommitError.new('Failed to create commit')
    end

    branch = repository.find_branch(branch_name)
    oldrev = find_oldrev_from_branch(newrev, branch)

    ref = Gitlab::Git::BRANCH_REF_PREFIX + branch_name
    update_ref_in_hooks(ref, newrev, oldrev)

    # If repo was empty expire cache
    repository.after_create if was_empty
    repository.after_create_branch if
      was_empty || Gitlab::Git.blank_ref?(oldrev)

    newrev
  end

  def find_oldrev_from_branch(newrev, branch)
    return Gitlab::Git::BLANK_SHA unless branch

    oldrev = branch.target

    if oldrev == repository.rugged.merge_base(newrev, branch.target)
      oldrev
    else
      raise Repository::CommitError.new('Branch diverged')
    end
  end

  def update_ref_in_hooks(ref, newrev, oldrev)
    with_hooks(ref, newrev, oldrev) do
      update_ref(ref, newrev, oldrev)
    end
  end

  def with_hooks(ref, newrev, oldrev)
    GitHooksService.new.execute(
      user,
      repository.project,
      oldrev,
      newrev,
      ref) do |service|

      yield(service)
    end
  end

  # Gitaly note: JV: wait with migrating #update_ref until we know how to migrate its call sites.
  def update_ref(ref, newrev, oldrev)
    # We use 'git update-ref' because libgit2/rugged currently does not
    # offer 'compare and swap' ref updates. Without compare-and-swap we can
    # (and have!) accidentally reset the ref to an earlier state, clobbering
    # commits. See also https://github.com/libgit2/libgit2/issues/1534.
    command = %W[#{Gitlab.config.git.bin_path} update-ref --stdin -z]
    _, status = Gitlab::Popen.popen(
      command,
      repository.path_to_repo) do |stdin|
      stdin.write("update #{ref}\x00#{newrev}\x00#{oldrev}\x00")
    end

    unless status.zero?
      raise Repository::CommitError.new(
        "Could not update branch #{Gitlab::Git.branch_name(ref)}." \
        " Please refresh and try again.")
    end
  end

  def update_autocrlf_option
    if repository.raw_repository.autocrlf != :input
      repository.raw_repository.autocrlf = :input
    end
  end
end

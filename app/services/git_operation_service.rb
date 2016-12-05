
GitOperationService = Struct.new(:user, :repository) do
  def add_branch(branch_name, newrev)
    ref = Gitlab::Git::BRANCH_REF_PREFIX + branch_name
    oldrev = Gitlab::Git::BLANK_SHA

    with_hooks_and_update_ref(ref, oldrev, newrev)
  end

  def rm_branch(branch)
    ref = Gitlab::Git::BRANCH_REF_PREFIX + branch.name
    oldrev = branch.dereferenced_target.id
    newrev = Gitlab::Git::BLANK_SHA

    with_hooks_and_update_ref(ref, oldrev, newrev)
  end

  def add_tag(tag_name, newrev, options = {})
    ref = Gitlab::Git::TAG_REF_PREFIX + tag_name
    oldrev = Gitlab::Git::BLANK_SHA

    with_hooks(ref, oldrev, newrev) do |service|
      raw_tag = repository.rugged.tags.create(tag_name, newrev, options)
      service.newrev = raw_tag.target_id
    end
  end

  # Whenever `source_branch` or `source_commit` is passed, if `branch`
  # doesn't exist, it would be created from `source_branch` or
  # `source_commit`. Should only pass one of them, not both.
  # If `source_project` is passed, and the branch doesn't exist,
  # it would try to find the source from it instead of current repository.
  def with_branch(
    branch_name,
    source_branch: nil,
    source_commit: nil,
    source_project: repository.project)

    if source_commit && source_branch
      raise ArgumentError, 'Should pass only :source_branch or :source_commit'
    end

    ref = Gitlab::Git::BRANCH_REF_PREFIX + branch_name
    oldrev = Gitlab::Git::BLANK_SHA

    if repository.branch_exists?(branch_name)
      oldrev = newrev = repository.commit(branch_name).sha

    elsif repository.project != source_project
      unless source_branch
        raise ArgumentError,
          'Should also pass :source_branch if' +
          ' :source_project is different from current project'
      end

      newrev = source_project.repository.commit(source_branch).try(:sha)

      unless newrev
        raise Repository::CommitError.new(
          "Cannot find branch #{branch_name} nor" \
          " #{source_branch} from" \
          " #{source_project.path_with_namespace}")
      end

    elsif source_commit || source_branch
      newrev = (source_commit || repository.commit(source_branch)).try(:sha)

      unless newrev
        raise Repository::CommitError.new(
          "Cannot find branch #{branch_name} nor" \
          " #{source_commit.try(:sha) || source_branch} from" \
          " #{repository.project.path_with_namespace}")
      end

    else # we want an orphan empty branch
      newrev = Gitlab::Git::BLANK_SHA
    end

    commit_with_hooks(ref, oldrev, newrev) do
      if repository.project != source_project
        repository.fetch_ref(
          source_project.repository.path_to_repo,
          "#{Gitlab::Git::BRANCH_REF_PREFIX}#{source_branch}",
          "#{Gitlab::Git::BRANCH_REF_PREFIX}#{branch_name}"
        )
      end

      yield(ref)
    end
  end

  private

  def commit_with_hooks(ref, oldrev, newrev)
    with_hooks_and_update_ref(ref, oldrev, newrev) do |service|
      was_empty = repository.empty?

      # Make commit
      nextrev = yield(ref)

      unless nextrev
        raise Repository::CommitError.new('Failed to create commit')
      end

      service.newrev = nextrev

      update_ref!(ref, nextrev, newrev)

      # If repo was empty expire cache
      repository.after_create if was_empty
      repository.after_create_branch if was_empty ||
                                        oldrev == Gitlab::Git::BLANK_SHA

      nextrev
    end
  end

  def with_hooks_and_update_ref(ref, oldrev, newrev)
    with_hooks(ref, oldrev, newrev) do |service|
      update_ref!(ref, newrev, oldrev)

      yield(service) if block_given?
    end
  end

  def with_hooks(ref, oldrev, newrev)
    update_autocrlf_option

    result = nil

    GitHooksService.new.execute(
      user,
      repository.path_to_repo,
      oldrev,
      newrev,
      ref) do |service|

      result = yield(service) if block_given?
    end

    result
  end

  def update_ref!(name, newrev, oldrev)
    # We use 'git update-ref' because libgit2/rugged currently does not
    # offer 'compare and swap' ref updates. Without compare-and-swap we can
    # (and have!) accidentally reset the ref to an earlier state, clobbering
    # commits. See also https://github.com/libgit2/libgit2/issues/1534.
    command = %W[#{Gitlab.config.git.bin_path} update-ref --stdin -z]
    _, status = Gitlab::Popen.popen(
      command,
      repository.path_to_repo) do |stdin|
      stdin.write("update #{name}\x00#{newrev}\x00#{oldrev}\x00")
    end

    unless status.zero?
      raise Repository::CommitError.new(
        "Could not update branch #{name.sub('refs/heads/', '')}." \
        " Please refresh and try again.")
    end
  end

  def update_autocrlf_option
    if repository.raw_repository.autocrlf != :input
      repository.raw_repository.autocrlf = :input
    end
  end
end

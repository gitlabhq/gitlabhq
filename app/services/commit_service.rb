require 'securerandom'

class CommitService
  def self.transaction(project, current_user, ref)
    repository = project.repository
    path_to_repo = repository.path_to_repo

    # Create temporary ref
    random_string = SecureRandom.hex
    tmp_ref = "refs/tmp/#{random_string}/head"
    target = repository.find_branch(ref).target
    repository.rugged.references.create(tmp_ref, target)

    # Make commit in tmp ref
    sha = yield(tmp_ref)

    unless sha
      raise 'Failed to create commit'
    end

    # Run GitLab pre-receive hook
    status = PreCommitService.new(project, current_user).execute(sha, ref)

    if status
      # Update head
      repository.rugged.references.update(Gitlab::Git::BRANCH_REF_PREFIX + ref, sha)

      # Run GitLab post receive hook
      PostCommitService.new(project, current_user).execute(sha, ref)
    else
      # Remove tmp ref and return error to user
      repository.rugged.references.delete(tmp_ref)

      raise 'Commit was rejected by pre-reveive hook'
    end
  end
end

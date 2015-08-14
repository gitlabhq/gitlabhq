require 'securerandom'

class CommitService
  class PreReceiveError < StandardError; end
  class CommitError < StandardError; end

  def self.transaction(project, current_user, ref)
    repository = project.repository
    path_to_repo = repository.path_to_repo
    empty_repo = repository.empty?

    # Create temporary ref
    random_string = SecureRandom.hex
    tmp_ref = "refs/tmp/#{random_string}/head"

    unless empty_repo
      target = repository.find_branch(ref).target
      repository.rugged.references.create(tmp_ref, target)
    end

    # Make commit in tmp ref
    sha = yield(tmp_ref)

    unless sha
      raise CommitError.new('Failed to create commit')
    end

    # Run GitLab pre-receive hook
    status = PreCommitService.new(project, current_user).execute(sha, ref)

    if status
      if empty_repo
        # Create branch
        repository.rugged.references.create(Gitlab::Git::BRANCH_REF_PREFIX + ref, sha)
      else
        # Update head
        current_target = repository.find_branch(ref).target

        # Make sure target branch was not changed during pre-receive hook
        if current_target == target
          repository.rugged.references.update(Gitlab::Git::BRANCH_REF_PREFIX + ref, sha)
        else
          raise CommitError.new('Commit was rejected because branch received new push')
        end
      end

      # Run GitLab post receive hook
      PostCommitService.new(project, current_user).execute(sha, ref)
    else
      # Remove tmp ref and return error to user
      repository.rugged.references.delete(tmp_ref)

      raise PreReceiveError.new('Commit was rejected by pre-reveive hook')
    end
  end
end

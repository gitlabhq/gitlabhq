require 'securerandom'

class CommitService
  class PreReceiveError < StandardError; end
  class CommitError < StandardError; end

  def self.transaction(project, current_user, branch)
    repository = project.repository
    path_to_repo = repository.path_to_repo
    empty_repo = repository.empty?
    oldrev = Gitlab::Git::BLANK_SHA
    ref = Gitlab::Git::BRANCH_REF_PREFIX + branch
    gl_id = Gitlab::ShellEnv.gl_id(current_user)

    # Create temporary ref
    random_string = SecureRandom.hex
    tmp_ref = "refs/tmp/#{random_string}/head"

    unless empty_repo
      oldrev = repository.find_branch(branch).target
      repository.rugged.references.create(tmp_ref, oldrev)
    end

    # Make commit in tmp ref
    newrev = yield(tmp_ref)

    unless newrev
      raise CommitError.new('Failed to create commit')
    end

    # Run GitLab pre-receive hook
    pre_receive_hook = Gitlab::Git::Hook.new('pre-receive', path_to_repo)
    status = pre_receive_hook.trigger(gl_id, oldrev, newrev, ref)

    if status
      if empty_repo
        # Create branch
        repository.rugged.references.create(ref, newrev)
      else
        # Update head
        current_head = repository.find_branch(branch).target

        # Make sure target branch was not changed during pre-receive hook
        if current_head == oldrev
          repository.rugged.references.update(ref, newrev)
        else
          raise CommitError.new('Commit was rejected because branch received new push')
        end
      end

      # Run GitLab post receive hook
      post_receive_hook = Gitlab::Git::Hook.new('post-receive', path_to_repo)
      status = post_receive_hook.trigger(gl_id, oldrev, newrev, ref)
    else
      # Remove tmp ref and return error to user
      repository.rugged.references.delete(tmp_ref)

      raise PreReceiveError.new('Commit was rejected by pre-reveive hook')
    end
  end
end

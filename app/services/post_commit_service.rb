class PostCommitService < BaseService
  def execute(sha, branch)
    commit = repository.commit(sha)
    full_ref = 'refs/heads/' + branch
    old_sha = commit.parent_id || Gitlab::Git::BLANK_SHA
    GitPushService.new.execute(project, current_user, old_sha, sha, full_ref)
  end
end

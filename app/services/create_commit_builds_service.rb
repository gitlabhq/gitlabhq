class CreateCommitBuildsService
  def execute(project, user, params)
    return false unless project.builds_enabled?

    sha = params[:checkout_sha] || params[:after]
    origin_ref = params[:ref]

    unless origin_ref && sha.present?
      return false
    end

    ref = Gitlab::Git.ref_name(origin_ref)

    # Skip branch removal
    if sha == Gitlab::Git::BLANK_SHA
      return false
    end

    tag = Gitlab::Git.tag_ref?(origin_ref)
    commit = project.ensure_ci_commit(sha)
    unless commit.skip_ci?
      commit.update_committed!
      commit.create_builds(ref, tag, user)
    end

    commit
  end
end

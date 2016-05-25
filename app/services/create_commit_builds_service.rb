class CreateCommitBuildsService
  def execute(project, user, params)
    return false unless project.builds_enabled?

    before_sha = params[:checkout_sha] || params[:before]
    sha = params[:checkout_sha] || params[:after]
    origin_ref = params[:ref]

    unless origin_ref && sha.present?
      return false
    end

    ref = Gitlab::Git.ref_name(origin_ref)
    tag = Gitlab::Git.tag_ref?(origin_ref)

    # Skip branch removal
    if sha == Gitlab::Git::BLANK_SHA
      return false
    end

    commit = Ci::Commit.new(project: project, sha: sha, ref: ref, before_sha: before_sha, tag: tag)

    # Skip creating ci_commit when no gitlab-ci.yml is found
    unless commit.ci_yaml_file
      return false
    end

    # Create a new ci_commit
    commit.save!

    # Skip creating builds for commits that have [ci skip]
    unless commit.skip_ci?
      # Create builds for commit
      commit.create_builds(user)
    end

    commit.touch
    commit
  end
end

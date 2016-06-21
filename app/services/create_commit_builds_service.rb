class CreateCommitBuildsService
  def execute(project, user, params, mirror_update: false)
    return false unless project.builds_enabled?

    return false if !project.mirror_trigger_builds? && mirror_update

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

    pipeline = Ci::Pipeline.new(project: project, sha: sha, ref: ref, before_sha: before_sha, tag: tag)

    # Skip creating pipeline when no gitlab-ci.yml is found
    unless pipeline.ci_yaml_file
      return false
    end

    # Create a new pipeline
    pipeline.save!

    # Skip creating builds for commits that have [ci skip]
    unless pipeline.skip_ci?
      # Create builds for commit
      pipeline.create_builds(user)
    end

    pipeline.touch
    pipeline
  end
end

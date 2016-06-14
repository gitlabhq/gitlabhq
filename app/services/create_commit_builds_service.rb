class CreateCommitBuildsService
  def execute(project, user, params)
    return unless project.builds_enabled?

    before_sha = params[:checkout_sha] || params[:before]
    sha = params[:checkout_sha] || params[:after]
    origin_ref = params[:ref]

    ref = Gitlab::Git.ref_name(origin_ref)
    tag = Gitlab::Git.tag_ref?(origin_ref)

    # Skip branch removal
    if sha == Gitlab::Git::BLANK_SHA
      return false
    end

    pipeline = Ci::Pipeline.new(project: project, sha: sha, ref: ref, before_sha: before_sha, tag: tag)

    # Skip creating pipeline when no gitlab-ci.yml is found
    unless pipeline.ci_yaml_file
      return pipeline
    end

    # Skip creating builds for commits that have [ci skip]
   if !pipeline.skip_ci? && pipeline.config_processor
      # Create builds for commit
      unless pipeline.build_builds(user)
        pipeline.errors.add(:base, 'No builds created')
        return pipeline
      end
    end

    # Create a new pipeline
    pipeline.save!

    pipeline.touch
    pipeline
  end
end

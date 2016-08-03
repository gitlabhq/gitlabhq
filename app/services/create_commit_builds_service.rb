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

    @pipeline = Ci::Pipeline.new(
      project: project,
      sha: sha,
      ref: ref,
      before_sha: before_sha,
      tag: tag,
      user: user)

    ##
    # Skip creating pipeline if no gitlab-ci.yml is found
    #
    unless @pipeline.ci_yaml_file
      return false
    end

    ##
    # Skip creating builds for commits that have [ci skip]
    # but save pipeline object
    #
    if @pipeline.skip_ci?
      return save_pipeline!
    end

    ##
    # Skip creating builds when CI config is invalid
    # but save pipeline object
    #
    unless @pipeline.config_processor
      return save_pipeline!
    end

    ##
    # Skip creating pipeline object if there are no builds for it.
    #
    unless @pipeline.create_builds(user)
      @pipeline.errors.add(:base, 'No builds created')
      return false
    end

    @pipeline.save!
    @pipeline
  end
end

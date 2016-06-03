class CreateCommitBuildsService
  def execute(project, user, params)
    return unless project.builds_enabled?

    before_sha = params[:checkout_sha] || params[:before]
    sha = params[:checkout_sha] || params[:after]
    origin_ref = params[:ref]

    ref = Gitlab::Git.ref_name(origin_ref)
    tag = Gitlab::Git.tag_ref?(origin_ref)

    commit = Ci::Commit.new(project: project, sha: sha, ref: ref, before_sha: before_sha, tag: tag)

    unless commit.ci_yaml_file
      commit.errors.add(:base, 'No .gitlab-ci.yml file found')
      return commit
    end

    # Make object as skipped
    if commit.skip_ci?
      commit.status = 'skipped'
      commit.save
      return commit
    end

    # Create builds for commit and
    #   skip saving pipeline when there are no builds
    unless commit.build_builds(user)
      # Save object when there are yaml errors
      unless commit.yaml_errors.present?
        commit.errors.add(:base, 'No builds created')
        return commit
      end
    end

    # Create a new ci_commit
    commit.save!
    commit.touch
    commit
  end
end

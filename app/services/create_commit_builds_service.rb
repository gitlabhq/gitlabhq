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

    commit = project.ci_commit(sha)
    unless commit
      commit = project.ci_commits.new(sha: sha)

      # Skip creating ci_commit when no gitlab-ci.yml is found
      unless commit.ci_yaml_file
        return false
      end

      # Create a new ci_commit
      commit.save!
    end

    # Skip creating builds for commits that have [ci skip]
    unless commit.skip_ci?
      # Create builds for commit
      tag = Gitlab::Git.tag_ref?(origin_ref)
      commit.update_committed!
      commit.create_builds(ref, tag, user)
    end

    commit
  end
end

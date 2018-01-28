class CreateGpgSignatureWorker
  include ApplicationWorker

  def perform(commit_sha, project_id)
    project = Project.find_by(id: project_id)
    return unless project

    commit = project.commit(commit_sha)

    return unless commit

    # This calculates and caches the signature in the database
    Gitlab::Gpg::Commit.new(commit).signature
  end
end

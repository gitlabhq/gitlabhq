class CreateGpgSignatureWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  def perform(commit_sha, project_id)
    project = Project.find_by(id: project_id)
    return unless project

    # This calculates and caches the signature in the database
    Gitlab::Gpg::Commit.new(project, commit_sha).signature
  end
end

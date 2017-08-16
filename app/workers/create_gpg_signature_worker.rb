class CreateGpgSignatureWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  def perform(commit_sha, project_id)
    project = Project.find_by(id: project_id)

    return unless project

    commit = project.commit(commit_sha)

    return unless commit

    commit.signature
  end
end

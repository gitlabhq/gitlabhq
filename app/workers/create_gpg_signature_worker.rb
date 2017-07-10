class CreateGpgSignatureWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  def perform(commit_sha, project_id)
    project = Project.find_by(id: project_id)

    unless project
      return Rails.logger.error("CreateGpgSignatureWorker: couldn't find project with ID=#{project_id}, skipping job")
    end

    commit = project.commit(commit_sha)

    unless commit
      return Rails.logger.error("CreateGpgSignatureWorker: couldn't find commit with commit_sha=#{commit_sha}, skipping job")
    end

    commit.signature
  end
end

class GitlabRemoveProjectExportWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform
    Project.remove_gitlab_exports!
  end
end

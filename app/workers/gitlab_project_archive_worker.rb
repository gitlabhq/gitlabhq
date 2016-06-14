class GitlabProjectArchiveWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform
    Project.archive_gitlab_exports!
  end
end

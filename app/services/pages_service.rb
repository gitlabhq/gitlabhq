class PagesService
  def execute(job)
    return unless Settings.pages.enabled
    return unless job.name == 'pages'
    return unless job.success?

    PagesWorker.perform_async(:deploy, job.id)
  end
end

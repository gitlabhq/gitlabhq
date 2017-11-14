class PagesService
  attr_reader :job

  def initialize(job)
    @job = job
  end

  def execute
    return unless Settings.pages.enabled
    return unless job.name == 'pages'
    return unless job.success?

    PagesWorker.perform_async(
      :deploy,
      job.project.id, job.project.full_path, 
      job.commit_id,
      job.id,
      job.project.pages_config)
  end
end

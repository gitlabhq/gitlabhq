class PagesWorker
  include ApplicationWorker

  sidekiq_options retry: 3

  def perform(action, *arg)
    send(action, *arg) # rubocop:disable GitlabSecurity/PublicSend
  end

  def deploy(job_id)
    register_attempt

    Ci::Build.find_by(id: job_id).try do |job|
      Projects::UpdatePagesService.new(job.project, job).execute
      Projects::UpdatePagesConfigurationService.new(job.project).execute
    end
  rescue => e
    register_failure
    raise e
  end

  def remove(namespace_path, project_path)
    full_path = File.join(Settings.pages.path, namespace_path, project_path)
    FileUtils.rm_r(full_path, force: true)
  end

  private

  def register_attempt
    pages_deployments_total_counter.increment
  end

  def register_failure
    pages_deployments_failed_total_counter.increment
  end

  def pages_deployments_total_counter
    @pages_deployments_total_counter ||= Gitlab::Metrics.counter(:pages_deployments_total, "Counter of GitLab Pages deployments triggered")
  end

  def pages_deployments_failed_total_counter
    @pages_deployments_failed_total_counter ||= Gitlab::Metrics.counter(:pages_deployments_failed_total, "Counter of GitLab Pages deployments which failed")
  end
end

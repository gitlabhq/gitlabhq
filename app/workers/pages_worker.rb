class PagesWorker
  include ApplicationWorker

  sidekiq_options retry: 3

  def perform(action, *arg)
    send(action, *arg) # rubocop:disable GitlabSecurity/PublicSend
  end

  def deploy(build_id)
    build = Ci::Build.find_by(id: build_id)
    result = Projects::UpdatePagesService.new(build.project, build).execute
    if result[:status] == :success
      result = Projects::UpdatePagesConfigurationService.new(build.project).execute
    end

    result
  end

  def remove(namespace_path, project_path)
    full_path = File.join(Settings.pages.path, namespace_path, project_path)
    FileUtils.rm_r(full_path, force: true)
  end
end

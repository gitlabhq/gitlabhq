class PagesWorker
  include Sidekiq::Worker

  sidekiq_options queue: :pages, retry: false

  def perform(action, *arg)
    send(action, *arg)
  end

  def deploy(build_id)
    build = Ci::Build.find_by(id: build_id)
    Projects::UpdatePagesService.new(build.project, build).execute
  end

  def remove(namespace_path, project_path)
    full_path = File.join(Settings.pages.path, namespace_path, project_path)
    FileUtils.rm_r(full_path, force: true)
  end
end

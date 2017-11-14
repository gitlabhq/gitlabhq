class PagesWorker
  include Sidekiq::Worker

  sidekiq_options queue: :pages, retry: false

  def perform(action, *arg)
    send(action, *arg) # rubocop:disable GitlabSecurity/PublicSend
  end

  def deploy(project_id, project_path, build_id)
    build = Ci::Build.find_by(id: build_id)
    result = Projects::UpdatePagesService.new(build.project, build).execute
    if result[:status] == :success
      result = Projects::UpdatePagesConfigurationService.new(build.project).execute
    end
    result
  end

  def remove(project_id, namespace_path, path)
    # 1. We rename pages to temporary directory
    # 3. We remove pages with force
    temp_path = "#{path}.#{SecureRandom.hex}.deleted"

    if Gitlab::PagesTransfer.new.rename_project(path, temp_path, namespace_path)
      full_path = File.join(Settings.pages.path, namespace_path, project_path)
      FileUtils.rm_r(full_path, force: true)
    end
  end

  def config(project_id, project_path, data)
    Projects::UpdatePagesConfigurationService.new(build.project).execute
  end

  def rename_namespace(project_id, full_path_was, full_path)
    Gitlab::PagesTransfer.new.rename_namespace(full_path_was, full_path)
  end

  def rename_project(project_id, path_was, path, full_path)
    Gitlab::PagesTransfer.new.rename_project(path_was, path, full_path)
  end

  def move_project(project_id, path, full_path_was, full_path)
    Gitlab::PagesTransfer.new.move_project(path, @old_namespace.full_path, @new_namespace.full_path)
  end
end

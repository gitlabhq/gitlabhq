class Projects::GithooksController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_admin_project!

  respond_to :html

  layout "project_settings"

  def index
    @hooks = list
  end

  def enable
    hook = load(params[:id])
    create_hooks(hook['hook'], hook['id'])
    flash[:notice] = 'You have successfully enbled ' + hook['name']

    redirect_to project_githooks_path(@project)
  end

  def disable
    hook = load(params[:id])
    delete_hooks(hook['hook'], hook['id'])
    flash[:notice] = 'You have successfully disabled ' + hook['name']

    redirect_to project_githooks_path(@project)
  end

  private

  def list
    githooks = []
    Dir.glob(File.join(githooks_path, '*.json')) do |githook_info|
      hook = JSON.parse(IO.read(githook_info))
      hook['id'] = File.basename(githook_info, '.json')
      hook['status'] = githook_status?(hook['id'])
      githooks << hook
    end
    githooks
  end

  def load(id)
    path = File.join(githooks_path, id + '.json')
    hook = JSON.parse(IO.read(path))
    hook['id'] = id
    hook['status'] = githook_status?(hook['id'])
    hook
  end

  def githooks_path
    return Gitlab.config.gitlab_shell.hooks_path
  end

  def githook_status?(id)
    path = File.join(@project.repository.path_to_repo, 'hooks', "*-#{id}")
    !Dir.glob(path).empty?
  end

  def create_hooks(type, name)
    project_path = @project.repository.path_to_repo

    # Add hook wrapper script
    hook = File.join(project_path, 'hooks', "#{type}")
    File.delete(hook) if File.exists?(hook)
    File.symlink(File.join(githooks_path, 'hook-wrapper'), hook)

    # Add the hook script
    hook = File.join(, 'hooks', "#{type}-#{name}")
    File.delete(hook) if File.exists?(hook)
    File.symlink(File.join(githooks_path, name), hook)
  end

  def delete_hooks(type, name)
    project_path = @project.repository.path_to_repo

    # Delete hook
    hook = File.join(project_path, 'hooks', "#{type}-#{name}")
    File.delete(hook) if File.exists?(hook)

    # Delete wrapper (if no more hooks are available)
    hook = File.join(project_path, 'hooks', "#{type}")
    path = File.join(project_path, 'hooks', "#{type}-*")
    File.delete(hook) if File.exists?(hook) && Dir.glob(path).empty?
  end
end

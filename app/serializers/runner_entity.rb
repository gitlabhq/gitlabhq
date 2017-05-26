class RunnerEntity < Grape::Entity
  include RequestAwareEntity

  expose :id, :description

  expose :edit_runner_path,
    if: -> (*) { can?(request.current_user, :admin_build, project)  } do |runner|
    edit_namespace_project_runner_path(project.namespace, project, runner)
  end

  private

  def project
    request.project
  end
end

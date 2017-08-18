class RunnerEntity < Grape::Entity
  include RequestAwareEntity

  expose :id, :description

  expose :edit_path,
    if: -> (*) { can?(request.current_user, :admin_build, project) && runner.specific? } do |runner|
    edit_project_runner_path(project, runner)
  end

  private

  alias_method :runner, :object

  def project
    request.project
  end
end

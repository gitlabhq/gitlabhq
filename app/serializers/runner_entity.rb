# frozen_string_literal: true

class RunnerEntity < Grape::Entity
  include RequestAwareEntity

  expose :id, :description, :short_sha

  expose :edit_path, if: -> (*) { can_edit_runner? } do |runner|
    edit_project_runner_path(project, runner)
  end

  private

  alias_method :runner, :object

  def project
    request.project
  end

  def can_edit_runner?
    can?(request.current_user, :update_runner, runner) && runner.project_type?
  end
end

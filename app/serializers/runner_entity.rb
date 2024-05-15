# frozen_string_literal: true

class RunnerEntity < Grape::Entity
  include RequestAwareEntity

  expose :id, :description, :short_sha

  expose :edit_path, if: ->(*) { can_edit_runner? } do |runner|
    edit_project_runner_path(project, runner)
  end

  expose :admin_path, if: ->(*) { can_admin_runner? } do |runner|
    Gitlab::Routing.url_helpers.admin_runner_url(runner)
  end

  private

  alias_method :runner, :object

  def project
    request.project
  end

  def current_user
    request.current_user
  end

  def can_edit_runner?
    can?(current_user, :update_runner, runner) && runner.project_type?
  end

  # can_admin_all_resources? is used here because the
  # path exposed is only available to admins
  def can_admin_runner?
    current_user&.can_admin_all_resources?
  end
end

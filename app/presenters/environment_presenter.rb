# frozen_string_literal: true

class EnvironmentPresenter < Gitlab::View::Presenter::Delegated
  presents ::Environment, as: :environment

  MAX_DEPLOYMENTS_COUNT = 1000
  MAX_DISPLAY_COUNT = '999+'

  def path
    project_environment_path(project, self)
  end

  def deployments_display_count
    count = all_deployments.limit(MAX_DEPLOYMENTS_COUNT).count
    count >= MAX_DEPLOYMENTS_COUNT ? MAX_DISPLAY_COUNT : count.to_s
  end
end

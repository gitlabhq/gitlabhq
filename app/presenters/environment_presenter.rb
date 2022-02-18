# frozen_string_literal: true

class EnvironmentPresenter < Gitlab::View::Presenter::Delegated
  presents ::Environment, as: :environment

  def path
    project_environment_path(project, self)
  end
end

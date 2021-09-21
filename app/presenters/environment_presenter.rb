# frozen_string_literal: true

class EnvironmentPresenter < Gitlab::View::Presenter::Delegated
  include ActionView::Helpers::UrlHelper

  presents ::Environment, as: :environment

  def path
    project_environment_path(project, self)
  end
end

# frozen_string_literal: true

class EnvironmentPresenter < Gitlab::View::Presenter::Delegated
  include ActionView::Helpers::UrlHelper

  presents :environment

  def path
    if Feature.enabled?(:expose_environment_path_in_alert_details, project)
      project_environment_path(project, self)
    end
  end
end

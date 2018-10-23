# frozen_string_literal: true

module Gitlab::ConfigHelper
  def gitlab_config_features
    Gitlab.config.gitlab.default_projects_features
  end

  def gitlab_config
    Gitlab.config.gitlab
  end
end

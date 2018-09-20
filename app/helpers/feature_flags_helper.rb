# frozen_string_literal: true

module FeatureFlagsHelper
  def unleash_api_url(project)
    "#{root_url(only_path: false)}api/v4/feature_flags/projects/#{project.id}/unleash"
  end

  def unleash_api_instanceid(project)
    project.feature_flag_access_token
  end
end

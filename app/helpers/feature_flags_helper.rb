# frozen_string_literal: true

module FeatureFlagsHelper
  include ::API::Helpers::RelatedResourcesHelpers

  def unleash_api_url(project)
    expose_url(api_v4_feature_flags_unleash_path(project_id: project.id))
  end

  def unleash_api_instance_id(project)
    project.feature_flags_client_token
  end

  def feature_flag_issues_links_endpoint(_project, _feature_flag, _user)
    ''
  end
end

FeatureFlagsHelper.prepend_mod_with('FeatureFlagsHelper')

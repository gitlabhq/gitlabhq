# frozen_string_literal: true

module FeatureFlagsHelper
  include ::API::Helpers::RelatedResourcesHelpers

  def unleash_api_url(project)
    expose_url(api_v4_feature_flags_unleash_path(project_id: project.id))
  end

  def unleash_api_instance_id(project)
    project.feature_flags_client_token
  end

  def edit_feature_flag_data
    {
      endpoint: project_feature_flag_path(@project, @feature_flag),
      project_id: @project.id,
      feature_flags_path: project_feature_flags_path(@project),
      environments_endpoint: search_project_environments_path(@project, format: :json),
      strategy_type_docs_page_path: help_page_path('operations/feature_flags.md', anchor: 'feature-flag-strategies'),
      environments_scope_docs_path: help_page_path(
        'ci/environments/_index.md',
        anchor: 'limit-the-environment-scope-of-a-cicd-variable'
      )
    }
  end
end

FeatureFlagsHelper.prepend_mod_with('FeatureFlagsHelper')

class Projects::FeatureFlagsController < Projects::ApplicationController
  respond_to :html

  def index
    @feature_flags = project.project_feature_flags
    @unleash_instanceid = project.project_feature_flags_access_tokens.first&.token || project.project_feature_flags_access_tokens.create!.token
  end
end

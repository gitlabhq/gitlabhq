# frozen_string_literal: true

class Projects::GoogleCloudController < Projects::ApplicationController
  feature_category :google_cloud

  before_action :admin_project_google_cloud?
  before_action :google_oauth2_enabled?
  before_action :feature_flag_enabled?

  def index
    @js_data = {
      serviceAccounts: GoogleCloud::ServiceAccountsService.new(project).find_for_project,
      createServiceAccountUrl: '#mocked-url-create-service',
      emptyIllustrationUrl: ActionController::Base.helpers.image_path('illustrations/pipelines_empty.svg')
    }.to_json
  end

  private

  def admin_project_google_cloud?
    access_denied! unless can?(current_user, :admin_project_google_cloud, project)
  end

  def google_oauth2_enabled?
    config = Gitlab::Auth::OAuth::Provider.config_for('google_oauth2')
    if config.app_id.blank? || config.app_secret.blank?
      access_denied! 'This GitLab instance not configured for Google Oauth2.'
    end
  end

  def feature_flag_enabled?
    access_denied! unless Feature.enabled?(:incubation_5mp_google_cloud)
  end
end

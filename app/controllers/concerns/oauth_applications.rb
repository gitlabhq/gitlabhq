# frozen_string_literal: true

module OauthApplications
  extend ActiveSupport::Concern

  CREATED_SESSION_KEY = :oauth_applications_created

  included do
    before_action :prepare_scopes, only: [:create, :update]
  end

  def prepare_scopes
    scopes = params.fetch(:doorkeeper_application, {}).fetch(:scopes, nil)

    params[:doorkeeper_application][:scopes] = scopes.join(' ') if scopes
  end

  def set_created_session
    session[CREATED_SESSION_KEY] = true
  end

  def get_created_session
    session.delete(CREATED_SESSION_KEY) || false
  end

  def load_scopes
    @scopes ||= Doorkeeper::OAuth::Scopes.from_array(
      Doorkeeper.configuration.scopes.to_a - [
        ::Gitlab::Auth::AI_WORKFLOW.to_s,
        ::Gitlab::Auth::DYNAMIC_USER.to_s,
        ::Gitlab::Auth::SELF_ROTATE_SCOPE.to_s
      ]
    )
  end

  def permitted_params
    %i[name redirect_uri scopes confidential]
  end

  def application_params
    params
      .require(:doorkeeper_application)
      .permit(*permitted_params)
  end
end

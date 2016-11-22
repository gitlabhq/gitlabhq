module OauthApplications
  extend ActiveSupport::Concern

  included do
    before_action :prepare_scopes, only: [:create, :update]
  end

  def prepare_scopes
    scopes = params.dig(:doorkeeper_application, :scopes)
    if scopes
      params[:doorkeeper_application][:scopes] = scopes.join(' ')
    end
  end
end

module OauthApplications
  extend ActiveSupport::Concern

  included do
    before_action :prepare_scopes, only: [:create, :update]
  end

  def prepare_scopes
<<<<<<< HEAD
    scopes = params.dig(:doorkeeper_application, :scopes)
=======
    scopes = params.fetch(:doorkeeper_application, {}).fetch(:scopes, nil)
>>>>>>> ce/master

    if scopes
      params[:doorkeeper_application][:scopes] = scopes.join(' ')
    end
  end

  def load_scopes
    @scopes = Doorkeeper.configuration.scopes
  end
end

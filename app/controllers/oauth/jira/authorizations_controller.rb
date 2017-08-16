class Oauth::Jira::AuthorizationsController < Doorkeeper::AuthorizationsController
  skip_before_action :authenticate_resource_owner!, only: :access_token
  skip_before_action :verify_authenticity_token, only: :access_token

  # Overriden from Doorkeeper::AuthorizationsController to
  # include the call to session.delete
  def new
    session[:redirect_uri] = params['redirect_uri']

    redirect_to oauth_authorization_path(client_id: params['client_id'],
                                         response_type: 'code',
                                         redirect_uri: 'http://glgh-api-proxy.ngrok.io/jira/login/oauth/authorize_callback')
  end

  def callback
    redirect_uri = session[:redirect_uri]
    session[:redirect_uri] = nil

    redirect_to(redirect_uri + '&code=' + params[:code])
  end

  def access_token
    req_params =  { client_id: params[:client_id],
                    client_secret: params[:client_secret],
                    code: params[:code],
                    grant_type: 'authorization_code',
                    redirect_uri: 'http://glgh-api-proxy.ngrok.io/jira/login/oauth/authorize_callback' }

    Rails.logger.info("------ #{req_params}")

    response = HTTParty.post('http://glgh-api-proxy.ngrok.io/jira/login/oauth/token', body: req_params)

    token = "access_token=" + response['access_token'] + "&scope=" + response['scope'] + "&token_type=" + response['token_type']

    render text: token
  end
end

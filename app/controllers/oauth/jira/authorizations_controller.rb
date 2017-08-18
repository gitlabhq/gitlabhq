# This controller's role is to mimic and rewire the Gitlab OAuth
# flow routes for Jira DVCS integration.
# See https://gitlab.com/gitlab-org/gitlab-ee/issues/2381
#
class Oauth::Jira::AuthorizationsController < ActionController::Base
  # 1. Rewire Jira OAuth initial request to our stablished OAuth authorization URL.
  def new
    session[:redirect_uri] = params['redirect_uri']

    redirect_to oauth_authorization_path(client_id: params['client_id'],
                                         response_type: 'code',
                                         redirect_uri: oauth_jira_callback_url)
  end

  # 2. Handle the callback call as we were a Github Enterprise instance client.
  def callback
    # TODO: join url params in a better way
    redirect_to(session['redirect_uri'] + '&code=' + params[:code])
  end

  # 3. Rewire and adjust access_token request accordingly.
  def access_token
    auth_params = params
                    .slice(:code, :client_id, :client_secret)
                    .merge(grant_type: 'authorization_code', redirect_uri: oauth_jira_callback_url)

    auth_response = HTTParty.post(oauth_token_url, body: auth_params)

    # TODO: join url params in a better way
    token = "access_token=" +
            auth_response['access_token'] + "&scope=" +
            auth_response['scope'] + "&token_type=" +
            auth_response['token_type']

    render text: token
  end
end

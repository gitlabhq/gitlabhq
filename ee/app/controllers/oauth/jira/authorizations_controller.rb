# This controller's role is to mimic and rewire the Gitlab OAuth
# flow routes for Jira DVCS integration.
# See https://gitlab.com/gitlab-org/gitlab-ee/issues/2381
#
class Oauth::Jira::AuthorizationsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  # 1. Rewire Jira OAuth initial request to our stablished OAuth authorization URL.
  def new
    session[:redirect_uri] = params['redirect_uri']

    redirect_to oauth_authorization_path(client_id: params['client_id'],
                                         response_type: 'code',
                                         redirect_uri: oauth_jira_callback_url)
  end

  # 2. Handle the callback call as we were a Github Enterprise instance client.
  def callback
    # Handling URI query params concatenation.
    redirect_uri = URI.parse(session['redirect_uri'])
    new_query = URI.decode_www_form(String(redirect_uri.query)) << ['code', params[:code]]
    redirect_uri.query = URI.encode_www_form(new_query)

    redirect_to redirect_uri.to_s
  end

  # 3. Rewire and adjust access_token request accordingly.
  def access_token
    auth_params = params
                    .slice(:code, :client_id, :client_secret)
                    .merge(grant_type: 'authorization_code', redirect_uri: oauth_jira_callback_url)

    auth_response = Gitlab::HTTP.post(oauth_token_url, body: auth_params, allow_local_requests: true)
    token_type, scope, token = auth_response['token_type'], auth_response['scope'], auth_response['access_token']

    render text: "access_token=#{token}&scope=#{scope}&token_type=#{token_type}"
  end
end

# frozen_string_literal: true

# This controller's role is to mimic and rewire the GitLab OAuth
# flow routes for Jira DVCS integration.
# See https://gitlab.com/gitlab-org/gitlab/issues/2381
#
class Oauth::JiraDvcs::AuthorizationsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  before_action :reversible_end_of_life!
  before_action :validate_redirect_uri, only: :new

  feature_category :integrations

  # 1. Rewire Jira OAuth initial request to our stablished OAuth authorization URL.
  def new
    session[:redirect_uri] = params['redirect_uri']

    redirect_to oauth_authorization_path(
      client_id: params['client_id'],
      response_type: 'code',
      scope: normalize_scope(params['scope']),
      redirect_uri: oauth_jira_dvcs_callback_url
    )
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
    # We have to modify request.parameters because Doorkeeper::Server reads params from there
    request.parameters[:redirect_uri] = oauth_jira_dvcs_callback_url

    strategy = Doorkeeper::Server.new(self).token_request('authorization_code')
    response = strategy.authorize

    if response.status == :ok
      access_token, scope, token_type = response.body.values_at('access_token', 'scope', 'token_type')

      render body: "access_token=#{access_token}&scope=#{scope}&token_type=#{token_type}"
    else
      render status: response.status, body: response.body
    end
  rescue Doorkeeper::Errors::DoorkeeperError => e
    render status: :unauthorized, body: e.type
  end

  private

  # The endpoints in this controller have been deprecated since 15.1.
  #
  # Due to uncertainty about the impact of a full removal in 16.0, all endpoints return `404`
  # by default but we allow customers to toggle a flag to reverse this breaking change.
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/362168#note_1347692683.
  #
  # TODO Make the breaking change irreversible https://gitlab.com/gitlab-org/gitlab/-/issues/408148.
  def reversible_end_of_life!
    render_404 unless Feature.enabled?(:jira_dvcs_end_of_life_amnesty)
  end

  # When using the GitHub Enterprise connector in Jira we receive the "repo" scope,
  # this doesn't exist in GitLab but we can map it to our "api" scope.
  def normalize_scope(scope)
    scope == 'repo' ? 'api' : scope
  end

  def validate_redirect_uri
    client = Doorkeeper::OAuth::Client.find(params[:client_id])
    return render_404 unless client

    return true if Doorkeeper::OAuth::Helpers::URIChecker.valid_for_authorization?(
      params['redirect_uri'], client.redirect_uri
    )

    render_403
  end
end

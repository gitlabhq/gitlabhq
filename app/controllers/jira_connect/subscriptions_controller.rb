# frozen_string_literal: true

class JiraConnect::SubscriptionsController < JiraConnect::ApplicationController
  ALLOWED_IFRAME_ANCESTORS = [:self, 'https://*.atlassian.net', 'https://*.jira.com'].freeze
  layout 'jira_connect'

  content_security_policy do |p|
    next if p.directives.blank?

    # rubocop: disable Lint/PercentStringArray
    script_src_values = Array.wrap(p.directives['script-src']) | %w['self' https://connect-cdn.atl-paas.net]
    style_src_values = Array.wrap(p.directives['style-src']) | %w['self' 'unsafe-inline']
    # rubocop: enable Lint/PercentStringArray

    # *.jira.com is needed for some legacy Jira Cloud instances, new ones will use *.atlassian.net
    # https://support.atlassian.com/organization-administration/docs/ip-addresses-and-domains-for-atlassian-cloud-products/
    p.frame_ancestors(*(ALLOWED_IFRAME_ANCESTORS + Gitlab.config.jira_connect.additional_iframe_ancestors))
    p.script_src(*script_src_values)
    p.style_src(*style_src_values)
  end

  before_action :allow_rendering_in_iframe, only: :index
  before_action :verify_qsh_claim!, only: :index
  before_action :allow_self_managed_content_security_policy, only: :index
  before_action :authenticate_user!, only: :create

  def index
    @subscriptions = current_jira_installation.subscriptions.preload_namespace_route

    respond_to do |format|
      format.html
      format.json do
        render json: JiraConnect::AppDataSerializer.new(@subscriptions).as_json
      end
    end
  end

  def create
    result = create_service.execute

    if result[:status] == :success
      render json: { success: true }
    else
      render json: { error: result[:message] }, status: result[:http_status]
    end
  end

  def destroy
    result = destroy_service.execute

    if result.success?
      render json: { success: true }
    else
      render json: { error: result.message }, status: result[:reason]
    end
  end

  private

  def allow_self_managed_content_security_policy
    return unless current_jira_installation.instance_url?

    request.content_security_policy.directives['connect-src'] ||= []
    request.content_security_policy.directives['connect-src'].concat(allowed_instance_connect_src)
  end

  def create_service
    JiraConnectSubscriptions::CreateService.new(
      current_jira_installation,
      current_user,
      namespace_path: params['namespace_path'],
      jira_user: jira_user
    )
  end

  def destroy_service
    subscription = current_jira_installation.subscriptions.find(params[:id])

    JiraConnectSubscriptions::DestroyService.new(subscription, jira_user)
  end

  def allow_rendering_in_iframe
    response.headers.delete('X-Frame-Options')
  end

  def allowed_instance_connect_src
    [
      Gitlab::Utils.append_path(current_jira_installation.instance_url, '/-/jira_connect/'),
      Gitlab::Utils.append_path(current_jira_installation.instance_url, '/api/'),
      Gitlab::Utils.append_path(current_jira_installation.instance_url, '/oauth/token')
    ]
  end
end

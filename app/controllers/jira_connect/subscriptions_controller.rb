# frozen_string_literal: true

class JiraConnect::SubscriptionsController < JiraConnect::ApplicationController
  ALLOWED_IFRAME_ANCESTORS = [
    :self,
    'https://*.atlassian.net',
    'https://*.jira.com',
    'https://*.atlassian-us-gov-mod.net'
  ].freeze
  GOV_CLOUD_CDN = 'https://*.cdn.atlassian-us-gov-mod.com'
  GOV_CLOUD_ATLASSIAN_JS_URL = 'https://connect-alljs-cdn-bifrost.frontend.cdn.atlassian-us-gov-mod.com/assets/all.js'
  layout 'jira_connect'
  helper_method :atlassian_js_url

  content_security_policy do |p|
    next if p.directives.blank?

    # rubocop: disable Lint/PercentStringArray
    script_src_values = Array.wrap(p.directives['script-src']) | %w['self' https://connect-cdn.atl-paas.net]
    style_src_values = Array.wrap(p.directives['style-src']) | %w['self' 'unsafe-inline']
    # rubocop: enable Lint/PercentStringArray

    if gov_cloud_installation?
      script_src_values |= [GOV_CLOUD_CDN]
      style_src_values |= [GOV_CLOUD_CDN]
    end

    # *.jira.com is needed for some legacy Jira Cloud instances, new ones will use *.atlassian.net
    # https://support.atlassian.com/organization-administration/docs/ip-addresses-and-domains-for-atlassian-cloud-products/
    frame_ancestors = ALLOWED_IFRAME_ANCESTORS + Gitlab.config.jira_connect.additional_iframe_ancestors

    # Add the specific Jira installation's domain (handles custom Jira domains)
    if current_jira_installation&.display_url.present? &&
        current_jira_installation.display_url != current_jira_installation.base_url
      frame_ancestors << current_jira_installation.display_url
    end

    p.frame_ancestors(*frame_ancestors)
    p.script_src(*script_src_values)
    p.style_src(*style_src_values)
  end

  before_action :allow_rendering_in_iframe, only: :index
  before_action :verify_qsh_claim!, only: :index
  before_action :allow_self_managed_content_security_policy, only: :index
  before_action only: :index do
    push_frontend_feature_flag(:vue3_migrate_jira_connect_app)
  end

  def index
    @subscriptions = current_jira_installation.subscriptions.preload_namespace_route

    respond_to do |format|
      format.html
      format.json do
        render json: JiraConnect::AppDataSerializer.new(@subscriptions).as_json
      end
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

  def gov_cloud_installation?
    Atlassian::JiraConnect.gov_cloud?(current_jira_installation.base_url)
  end

  def atlassian_js_url
    return GOV_CLOUD_ATLASSIAN_JS_URL if gov_cloud_installation?

    Gitlab.config.jira_connect.atlassian_js_url
  end

  def allow_self_managed_content_security_policy
    return unless current_jira_installation.instance_url?

    request.content_security_policy.directives['connect-src'] ||= []
    request.content_security_policy.directives['connect-src'].concat(allowed_instance_connect_src)
  end

  def destroy_service
    subscription = current_jira_installation.subscriptions.find(params.permit(:id)[:id])

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

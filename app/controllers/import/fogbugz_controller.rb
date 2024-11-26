# frozen_string_literal: true

class Import::FogbugzController < Import::BaseController
  extend ::Gitlab::Utils::Override

  before_action :verify_fogbugz_import_enabled
  before_action -> { check_rate_limit!(:fogbugz_import, scope: current_user, redirect_back: true) }, only: :callback

  before_action :user_map, only: [:new_user_map, :create_user_map]
  before_action :verify_blocked_uri, only: :callback

  rescue_from Fogbugz::AuthenticationException, with: :fogbugz_unauthorized

  def new; end

  def callback
    begin
      res = Gitlab::FogbugzImport::Client.new(import_params.to_h.symbolize_keys)
    rescue StandardError
      # If the URI is invalid various errors can occur
      return redirect_to new_import_fogbugz_path(namespace_id: params[:namespace_id]),
        alert: _('Could not connect to FogBugz, check your URL')
    end
    session[:fogbugz_token] = res.get_token.to_s
    session[:fogbugz_uri] = params[:uri]

    redirect_to new_user_map_import_fogbugz_path(namespace_id: params[:namespace_id])
  end

  def new_user_map; end

  def create_user_map
    user_map = user_map_params.to_h[:users]

    unless user_map.is_a?(Hash) && user_map.all? { |k, v| !v[:name].blank? }
      flash.now[:alert] = _('All users must have a name.')

      return render 'new_user_map'
    end

    session[:fogbugz_user_map] = user_map

    flash[:notice] = _('The user map has been saved. Continue by selecting the projects you want to import.')

    redirect_to status_import_fogbugz_path(namespace_id: params[:namespace_id])
  end

  def status
    return redirect_to new_import_fogbugz_path(namespace_id: params[:namespace_id]) unless client.valid?

    super
  end

  def create
    credentials = { uri: session[:fogbugz_uri], token: session[:fogbugz_token] }

    service_params = params.merge({
      umap: session[:fogbugz_user_map] || client.user_map,
      organization_id: Current.organization_id
    })

    result = Import::FogbugzService.new(client, current_user, service_params).execute(credentials)

    if result[:status] == :success
      render json: ProjectSerializer.new.represent(result[:project], serializer: :import)
    else
      render json: { errors: result[:message] }, status: result[:http_status]
    end
  end

  protected

  override :importable_repos
  def importable_repos
    client.repos
  end

  override :incompatible_repos
  def incompatible_repos
    []
  end

  override :provider_name
  def provider_name
    :fogbugz
  end

  override :provider_url
  def provider_url
    session[:fogbugz_uri]
  end

  private

  def client
    @client ||= Gitlab::FogbugzImport::Client.new(token: session[:fogbugz_token], uri: session[:fogbugz_uri])
  end

  def user_map
    @user_map ||= begin
      user_map = client.user_map

      stored_user_map = session[:fogbugz_user_map]
      user_map.update(stored_user_map) if stored_user_map

      user_map
    end
  end

  def fogbugz_unauthorized(exception)
    redirect_to new_import_fogbugz_path(namespace_id: params[:namespace_id]), alert: exception.message
  end

  def import_params
    params.permit(:uri, :email, :password)
  end

  def user_map_params
    params.permit(users: %w[name email gitlab_user])
  end

  def verify_fogbugz_import_enabled
    render_404 unless fogbugz_import_enabled?
  end

  def verify_blocked_uri
    Gitlab::HTTP_V2::UrlBlocker.validate!(
      params[:uri],
      allow_localhost: allow_local_requests?,
      allow_local_network: allow_local_requests?,
      deny_all_requests_except_allowed: deny_all_requests_except_allowed?,
      schemes: %w[http https],
      outbound_local_requests_allowlist: Gitlab::CurrentSettings.outbound_local_requests_whitelist # rubocop:disable Naming/InclusiveLanguage -- existing setting
    )
  rescue Gitlab::HTTP_V2::UrlBlocker::BlockedUrlError => e
    redirect_to new_import_fogbugz_url, alert: _('Specified URL cannot be used: "%{reason}"') % { reason: e.message }
  end

  def allow_local_requests?
    Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
  end

  def deny_all_requests_except_allowed?
    Gitlab::CurrentSettings.deny_all_requests_except_allowed?
  end
end

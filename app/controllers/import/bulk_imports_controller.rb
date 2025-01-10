# frozen_string_literal: true

class Import::BulkImportsController < ApplicationController
  include ActionView::Helpers::SanitizeHelper

  before_action :ensure_bulk_import_enabled
  before_action :verify_blocked_uri, only: :status
  before_action :bulk_import, only: [:history, :failures]

  feature_category :importers
  urgency :low

  POLLING_INTERVAL = 3_000

  rescue_from BulkImports::Error, with: :bulk_import_connection_error

  def configure
    session[access_token_key] = configure_params[access_token_key]&.strip
    session[url_key] = configure_params[url_key]

    verify_blocked_uri && performed? && return
    validate_configure_params!

    redirect_to status_import_bulk_imports_url(namespace_id: params[:namespace_id])
  end

  def status
    respond_to do |format|
      format.json do
        data = ::BulkImports::GetImportableDataService.new(params, query_params, credentials).execute

        pagination_headers.each do |header|
          response.set_header(header, data[:response].headers[header])
        end

        json_response = { importable_data: serialized_data(data[:response].parsed_response) }
        json_response[:version_validation] = data[:version_validation]

        render json: json_response
      end
      format.html do
        if params[:namespace_id]
          @namespace = Namespace.find_by_id(params[:namespace_id])

          render_404 unless current_user.can?(:create_subgroup, @namespace)
        end

        @source_url = session[url_key]
      end
    end
  end

  def history; end

  def failures
    bulk_import_entity
  end

  def create
    return render json: { success: false }, status: :too_many_requests if throttled_request?
    return render json: { success: false }, status: :unprocessable_entity unless valid_create_params?

    responses = create_params.map do |entry|
      if entry[:destination_name]
        entry[:destination_slug] ||= entry[:destination_name]
        entry.delete(:destination_name)
      end

      ::BulkImports::CreateService.new(
        current_user, entry, credentials, fallback_organization: Current.organization
      ).execute
    end

    render json: responses.map { |response|
      { success: response.success?, id: response.payload[:id], message: response.message }
    }
  end

  def realtime_changes
    Gitlab::PollingInterval.set_header(response, interval: POLLING_INTERVAL)

    render json: current_user_bulk_imports.to_json(only: [:id], methods: [:status_name, :has_failures])
  end

  private

  def bulk_import
    return unless params[:id]

    @bulk_import ||= BulkImport.find(params[:id])
    @bulk_import || render_404
  end

  def bulk_import_entity
    @bulk_import_entity ||= @bulk_import.entities.find(params[:entity_id])
  end

  def pagination_headers
    %w[x-next-page x-page x-per-page x-prev-page x-total x-total-pages]
  end

  def serialized_data(data)
    serializer.represent(data, {}, Import::BulkImportEntity)
  end

  def serializer
    @serializer ||= BaseSerializer.new(current_user: current_user)
  end

  # Default query string params used to fetch groups from GitLab source instance
  #
  # top_level_only: fetch only top level groups (subgroups are fetched during import itself)
  # min_access_level: fetch only groups user has maintainer or above permissions
  # search: optional search param to search user's groups by a keyword
  def query_params
    query_params = {
      top_level_only: true,
      min_access_level: Gitlab::Access::OWNER
    }

    query_params[:search] = sanitized_filter_param if sanitized_filter_param
    query_params
  end

  def configure_params
    params.permit(access_token_key, url_key)
  end

  def validate_configure_params!
    client = BulkImports::Clients::HTTP.new(
      url: credentials[:url],
      token: credentials[:access_token]
    )

    client.validate_instance_version!
    client.validate_import_scopes!
  end

  def create_params
    params.permit(bulk_import: bulk_import_params)[:bulk_import]
  end

  def valid_create_params?
    create_params.all? { _1[:source_type] == 'group_entity' }
  end

  def bulk_import_params
    %i[
      source_type
      source_full_path
      destination_name
      destination_slug
      destination_namespace
      migrate_projects
      migrate_memberships
    ]
  end

  def ensure_bulk_import_enabled
    render_404 unless Gitlab::CurrentSettings.bulk_import_enabled?
  end

  def access_token_key
    :bulk_import_gitlab_access_token
  end

  def url_key
    :bulk_import_gitlab_url
  end

  def verify_blocked_uri
    Gitlab::HTTP_V2::UrlBlocker.validate!(
      session[url_key],
      allow_localhost: allow_local_requests?,
      allow_local_network: allow_local_requests?,
      schemes: %w[http https],
      deny_all_requests_except_allowed: Gitlab::CurrentSettings.deny_all_requests_except_allowed?,
      outbound_local_requests_allowlist: Gitlab::CurrentSettings.outbound_local_requests_whitelist # rubocop:disable Naming/InclusiveLanguage -- existing setting
    )
  rescue Gitlab::HTTP_V2::UrlBlocker::BlockedUrlError => e
    clear_session_data

    redirect_to new_group_path(anchor: 'import-group-pane'),
      alert: _('Specified URL cannot be used: "%{reason}"') % { reason: e.message }
  end

  def allow_local_requests?
    Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
  end

  def bulk_import_connection_error(error)
    clear_session_data

    error_message = _("Unable to connect to server: %{error}") % { error: error }
    flash[:alert] = error_message

    respond_to do |format|
      format.json do
        render json: {
          error: {
            message: error_message,
            redirect: new_group_path
          }
        }, status: :unprocessable_entity
      end
      format.html do
        redirect_to new_group_path(anchor: 'import-group-pane')
      end
    end
  end

  def clear_session_data
    session[url_key] = nil
    session[access_token_key] = nil
  end

  def credentials
    {
      url: session[url_key],
      access_token: session[access_token_key]
    }
  end

  def sanitized_filter_param
    @filter ||= sanitize(params[:filter])&.downcase
  end

  def current_user_bulk_imports
    current_user.bulk_imports.gitlab
  end

  def throttled_request?
    ::Gitlab::ApplicationRateLimiter.throttled_request?(request, current_user, :bulk_import, scope: current_user)
  end
end

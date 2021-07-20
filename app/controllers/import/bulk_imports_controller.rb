# frozen_string_literal: true

class Import::BulkImportsController < ApplicationController
  include ActionView::Helpers::SanitizeHelper

  before_action :ensure_group_import_enabled
  before_action :verify_blocked_uri, only: :status

  feature_category :importers

  POLLING_INTERVAL = 3_000

  rescue_from BulkImports::Error, with: :bulk_import_connection_error

  def configure
    session[access_token_key] = configure_params[access_token_key]&.strip
    session[url_key] = configure_params[url_key]

    redirect_to status_import_bulk_imports_url
  end

  def status
    respond_to do |format|
      format.json do
        data = importable_data

        pagination_headers.each do |header|
          response.set_header(header, data.headers[header])
        end

        render json: { importable_data: serialized_data(data.parsed_response) }
      end
      format.html do
        @source_url = session[url_key]
      end
    end
  end

  def create
    response = BulkImportService.new(current_user, create_params, credentials).execute

    if response.success?
      render json: response.payload.to_json(only: [:id])
    else
      render json: { error: response.message }, status: response.http_status
    end
  end

  def realtime_changes
    Gitlab::PollingInterval.set_header(response, interval: POLLING_INTERVAL)

    render json: current_user_bulk_imports.to_json(only: [:id], methods: [:status_name])
  end

  private

  def pagination_headers
    %w[x-next-page x-page x-per-page x-prev-page x-total x-total-pages]
  end

  def serialized_data(data)
    serializer.represent(data, {}, Import::BulkImportEntity)
  end

  def serializer
    @serializer ||= BaseSerializer.new(current_user: current_user)
  end

  def importable_data
    client.get('groups', query_params)
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

  def client
    @client ||= BulkImports::Clients::HTTP.new(
      url: session[url_key],
      token: session[access_token_key],
      per_page: params[:per_page],
      page: params[:page]
    )
  end

  def configure_params
    params.permit(access_token_key, url_key)
  end

  def create_params
    params.permit(bulk_import: bulk_import_params)[:bulk_import]
  end

  def bulk_import_params
    %i[
      source_type
      source_full_path
      destination_name
      destination_namespace
    ]
  end

  def ensure_group_import_enabled
    render_404 unless Feature.enabled?(:bulk_import)
  end

  def access_token_key
    :bulk_import_gitlab_access_token
  end

  def url_key
    :bulk_import_gitlab_url
  end

  def verify_blocked_uri
    Gitlab::UrlBlocker.validate!(
      session[url_key],
      allow_localhost: allow_local_requests?,
      allow_local_network: allow_local_requests?,
      schemes: %w(http https)
    )
  rescue Gitlab::UrlBlocker::BlockedUrlError => e
    clear_session_data

    redirect_to new_group_path(anchor: 'import-group-pane'), alert: _('Specified URL cannot be used: "%{reason}"') % { reason: e.message }
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
end

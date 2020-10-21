# frozen_string_literal: true

class Import::BulkImportsController < ApplicationController
  before_action :ensure_group_import_enabled
  before_action :verify_blocked_uri, only: :status

  feature_category :importers

  rescue_from Gitlab::BulkImport::Client::ConnectionError, with: :bulk_import_connection_error

  def configure
    session[access_token_key] = params[access_token_key]&.strip
    session[url_key] = params[url_key]

    redirect_to status_import_bulk_import_url
  end

  def status
    respond_to do |format|
      format.json do
        render json: { importable_data: serialized_importable_data }
      end

      format.html
    end
  end

  private

  def serialized_importable_data
    serializer.represent(importable_data, {}, Import::BulkImportEntity)
  end

  def serializer
    @serializer ||= BaseSerializer.new(current_user: current_user)
  end

  def importable_data
    client.get('groups', top_level_only: true)
  end

  def client
    @client ||= Gitlab::BulkImport::Client.new(
      uri: session[url_key],
      token: session[access_token_key]
    )
  end

  def import_params
    params.permit(access_token_key, url_key)
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
      **{
        allow_localhost: allow_local_requests?,
        allow_local_network: allow_local_requests?,
        schemes: %w(http https)
      }
    )
  rescue Gitlab::UrlBlocker::BlockedUrlError => e
    clear_session_data

    redirect_to new_group_path, alert: _('Specified URL cannot be used: "%{reason}"') % { reason: e.message }
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
        redirect_to new_group_path
      end
    end
  end

  def clear_session_data
    session[url_key] = nil
    session[access_token_key] = nil
  end
end

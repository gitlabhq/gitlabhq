# frozen_string_literal: true

class Groups::DependencyProxyForContainersController < ::Groups::DependencyProxy::ApplicationController
  include Gitlab::Utils::StrongMemoize
  include DependencyProxy::GroupAccess
  include SendFileUpload
  include ::PackagesHelper # for event tracking
  include WorkhorseRequest

  before_action :ensure_group
  before_action :ensure_token_granted!, only: [:blob, :manifest]
  before_action :ensure_feature_enabled!

  before_action :verify_workhorse_api!, only: [:authorize_upload_blob, :upload_blob]
  skip_before_action :verify_authenticity_token, only: [:authorize_upload_blob, :upload_blob]

  attr_reader :token

  feature_category :dependency_proxy

  def manifest
    result = DependencyProxy::FindOrCreateManifestService.new(group, image, tag, token).execute

    if result[:status] == :success
      response.headers['Docker-Content-Digest'] = result[:manifest].digest
      response.headers['Content-Length'] = result[:manifest].size
      response.headers['Docker-Distribution-Api-Version'] = DependencyProxy::DISTRIBUTION_API_VERSION
      response.headers['Etag'] = "\"#{result[:manifest].digest}\""
      content_type = result[:manifest].content_type

      event_name = tracking_event_name(object_type: :manifest, from_cache: result[:from_cache])
      track_package_event(event_name, :dependency_proxy, namespace: group, user: auth_user)
      send_upload(
        result[:manifest].file,
        proxy: true,
        redirect_params: { query: { 'response-content-type' => content_type } },
        send_params: { type: content_type }
      )
    else
      render status: result[:http_status], json: result[:message]
    end
  end

  def blob
    return blob_via_workhorse if Feature.enabled?(:dependency_proxy_workhorse, group, default_enabled: :yaml)

    result = DependencyProxy::FindOrCreateBlobService
      .new(group, image, token, params[:sha]).execute

    if result[:status] == :success
      event_name = tracking_event_name(object_type: :blob, from_cache: result[:from_cache])
      track_package_event(event_name, :dependency_proxy, namespace: group, user: auth_user)
      send_upload(result[:blob].file)
    else
      head result[:http_status]
    end
  end

  def authorize_upload_blob
    set_workhorse_internal_api_content_type

    render json: DependencyProxy::FileUploader.workhorse_authorize(has_length: false)
  end

  def upload_blob
    @group.dependency_proxy_blobs.create!(
      file_name: blob_file_name,
      file: params[:file],
      size: params[:file].size
    )

    event_name = tracking_event_name(object_type: :blob, from_cache: false)
    track_package_event(event_name, :dependency_proxy, namespace: group, user: auth_user)

    head :ok
  end

  private

  def blob_via_workhorse
    blob = @group.dependency_proxy_blobs.find_by_file_name(blob_file_name)

    if blob.present?
      event_name = tracking_event_name(object_type: :blob, from_cache: true)
      track_package_event(event_name, :dependency_proxy, namespace: group, user: auth_user)

      send_upload(blob.file)
    else
      send_dependency(token, DependencyProxy::Registry.blob_url(image, params[:sha]), blob_file_name)
    end
  end

  def blob_file_name
    @blob_file_name ||= params[:sha].sub('sha256:', '') + '.gz'
  end

  def group
    strong_memoize(:group) do
      Group.find_by_full_path(params[:group_id], follow_redirects: true)
    end
  end

  def image
    params[:image]
  end

  def tag
    params[:tag]
  end

  def tracking_event_name(object_type:, from_cache:)
    event_name = "pull_#{object_type}"
    event_name = "#{event_name}_from_cache" if from_cache

    event_name
  end

  def dependency_proxy
    @dependency_proxy ||=
      group.dependency_proxy_setting || group.create_dependency_proxy_setting
  end

  def ensure_group
    render_404 unless group
  end

  def ensure_feature_enabled!
    render_404 unless dependency_proxy.enabled
  end

  def ensure_token_granted!
    result = DependencyProxy::RequestTokenService.new(image).execute

    if result[:status] == :success
      @token = result[:token]
    else
      render status: result[:http_status], json: result[:message]
    end
  end
end

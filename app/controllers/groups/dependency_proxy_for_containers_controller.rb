# frozen_string_literal: true

class Groups::DependencyProxyForContainersController < ::Groups::DependencyProxy::ApplicationController
  include DependencyProxy::GroupAccess
  include SendFileUpload
  include ::PackagesHelper # for event tracking
  include WorkhorseRequest
  include Gitlab::Utils::StrongMemoize

  before_action :ensure_group
  before_action :ensure_token_granted!, only: [:blob, :manifest]
  before_action :ensure_feature_enabled!

  before_action :verify_workhorse_api!,
    only: [:authorize_upload_blob, :upload_blob, :authorize_upload_manifest, :upload_manifest]
  skip_before_action :verify_authenticity_token,
    only: [:authorize_upload_blob, :upload_blob, :authorize_upload_manifest, :upload_manifest]

  attr_reader :token

  feature_category :virtual_registry
  urgency :low

  PERMITTED_PARAMS = [:image, :tag, :file, :sha, :group_id].freeze

  def manifest
    result = DependencyProxy::FindCachedManifestService.new(group, image, tag, token).execute

    if result[:status] == :success
      if result[:manifest]
        send_manifest(result[:manifest], from_cache: result[:from_cache])
      else
        send_dependency(manifest_header, DependencyProxy::Registry.manifest_url(image, tag), manifest_file_name)
      end
    else
      render status: result[:http_status], json: result[:message]
    end
  end

  def blob
    blob = @group.dependency_proxy_blobs.find_by_file_name(blob_file_name)

    if blob.present?
      event_name = tracking_event_name(object_type: :blob, from_cache: true)
      track_package_event(event_name, :dependency_proxy, namespace: group, user: auth_user)

      send_upload(blob.file)
    else
      send_dependency(token_header, DependencyProxy::Registry.blob_url(image, permitted_params[:sha]), blob_file_name)
    end
  end

  def authorize_upload_blob
    set_workhorse_internal_api_content_type

    render json: DependencyProxy::FileUploader.workhorse_authorize(has_length: false,
      maximum_size: DependencyProxy::Blob::MAX_FILE_SIZE)
  end

  def upload_blob
    @group.dependency_proxy_blobs.create!(
      file_name: blob_file_name,
      file: permitted_params[:file],
      size: permitted_params[:file].size
    )

    event_name = tracking_event_name(object_type: :blob, from_cache: false)
    track_package_event(event_name, :dependency_proxy, namespace: group, user: auth_user)

    head :ok
  end

  def authorize_upload_manifest
    set_workhorse_internal_api_content_type

    render json: DependencyProxy::FileUploader.workhorse_authorize(has_length: false,
      maximum_size: DependencyProxy::Manifest::MAX_FILE_SIZE)
  end

  def upload_manifest
    attrs = {
      file_name: manifest_file_name,
      content_type: request.headers[Gitlab::Workhorse::SEND_DEPENDENCY_CONTENT_TYPE_HEADER],
      digest: request.headers[DependencyProxy::Manifest::DIGEST_HEADER],
      file: permitted_params[:file],
      size: permitted_params[:file].size
    }

    manifest = @group.dependency_proxy_manifests
                     .active
                     .find_by_file_name(manifest_file_name)

    if manifest
      manifest.update!(attrs)
    else
      @group.dependency_proxy_manifests.create!(attrs)
    end

    event_name = tracking_event_name(object_type: :manifest, from_cache: false)
    track_package_event(event_name, :dependency_proxy, namespace: group, user: auth_user)

    head :ok
  end

  private

  def group
    Group.find_by_full_path(permitted_params[:group_id], follow_redirects: true)
  end
  strong_memoize_attr :group

  def send_manifest(manifest, from_cache:)
    response.headers[DependencyProxy::Manifest::DIGEST_HEADER] = manifest.digest
    response.headers['Content-Length'] = manifest.size
    response.headers['Docker-Distribution-Api-Version'] = DependencyProxy::DISTRIBUTION_API_VERSION
    response.headers['Etag'] = "\"#{manifest.digest}\""
    content_type = manifest.content_type

    event_name = tracking_event_name(object_type: :manifest, from_cache: from_cache)
    track_package_event(event_name, :dependency_proxy, namespace: group, user: auth_user)

    send_upload(
      manifest.file,
      proxy: true,
      redirect_params: { query: { 'response-content-type' => content_type } },
      send_params: { type: content_type }
    )
  end

  def blob_file_name
    @blob_file_name ||= "#{permitted_params[:sha].sub('sha256:', '')}.gz"
  end

  def manifest_file_name
    @manifest_file_name ||= Gitlab::PathTraversal.check_path_traversal!("#{image}:#{tag}.json")
  end

  def image
    permitted_params[:image]
  end

  def tag
    permitted_params[:tag]
  end

  def permitted_params
    params.permit(PERMITTED_PARAMS)
  end

  def tracking_event_name(object_type:, from_cache:)
    event_name = "pull_#{object_type}"
    event_name = "#{event_name}_from_cache" if from_cache

    event_name
  end

  def dependency_proxy
    @dependency_proxy ||= group.dependency_proxy_setting
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

  def token_header
    { Authorization: ["Bearer #{token}"] }
  end

  def manifest_header
    token_header.merge(Accept: ::DependencyProxy::Manifest::ACCEPTED_TYPES)
  end
end

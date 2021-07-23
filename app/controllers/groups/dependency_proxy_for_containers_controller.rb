# frozen_string_literal: true

class Groups::DependencyProxyForContainersController < Groups::ApplicationController
  include DependencyProxy::Auth
  include DependencyProxy::GroupAccess
  include SendFileUpload
  include ::PackagesHelper # for event tracking

  before_action :ensure_token_granted!
  before_action :ensure_feature_enabled!

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
      track_package_event(event_name, :dependency_proxy, namespace: group, user: current_user)
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
    result = DependencyProxy::FindOrCreateBlobService
      .new(group, image, token, params[:sha]).execute

    if result[:status] == :success
      event_name = tracking_event_name(object_type: :blob, from_cache: result[:from_cache])
      track_package_event(event_name, :dependency_proxy, namespace: group, user: current_user)
      send_upload(result[:blob].file)
    else
      head result[:http_status]
    end
  end

  private

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

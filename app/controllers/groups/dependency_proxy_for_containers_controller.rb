# frozen_string_literal: true

class Groups::DependencyProxyForContainersController < Groups::ApplicationController
  include DependencyProxy::Auth
  include DependencyProxy::GroupAccess
  include SendFileUpload

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

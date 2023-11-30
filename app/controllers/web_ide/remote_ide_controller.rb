# frozen_string_literal: true

require 'uri'

module WebIde
  class RemoteIdeController < ApplicationController
    include WebIdeCSP

    rescue_from URI::InvalidComponentError, with: :render_404

    before_action :allow_remote_ide_content_security_policy

    feature_category :remote_development

    urgency :low

    def index
      return render_404 unless Feature.enabled?(:vscode_web_ide, current_user)

      render layout: 'fullscreen', locals: { data: root_element_data }
    end

    private

    def allow_remote_ide_content_security_policy
      return if request.content_security_policy.directives.blank?

      default_src = Array(request.content_security_policy.directives['default-src'] || [])

      request.content_security_policy.directives['connect-src'] ||= default_src
      request.content_security_policy.directives['connect-src'].concat(connect_src_urls)
    end

    def connect_src_urls
      # It's okay if "port" is null
      host, port = params.require(:remote_host).split(':')

      # This could throw URI::InvalidComponentError. We go ahead and let it throw
      # and let the controller recover with a bad_request response
      %w[ws wss http https].map { |scheme| URI::Generic.build(scheme: scheme, host: host, port: port).to_s }
    end

    def root_element_data
      {
        connection_token: params.fetch(:connection_token, ''),
        remote_host: params.require(:remote_host),
        remote_path: params.fetch(:remote_path, ''),
        return_url: params.fetch(:return_url, ''),
        csp_nonce: content_security_policy_nonce
      }
    end
  end
end

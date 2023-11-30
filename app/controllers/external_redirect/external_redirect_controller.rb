# frozen_string_literal: true

module ExternalRedirect
  class ExternalRedirectController < ApplicationController
    feature_category :navigation
    skip_before_action :authenticate_user!
    before_action :check_url_param

    def index
      if known_url?
        redirect_to url_param
      else
        render layout: 'fullscreen', locals: {
          url: url_param
        }
      end
    end

    private

    def url_param
      params['url']&.strip
    end

    def known_url?
      uri_data = Addressable::URI.parse(url_param)

      uri_data.site == Gitlab.config.gitlab.url
    end

    def check_url_param
      render_404 unless ::Gitlab::UrlSanitizer.valid_web?(url_param)
    end
  end
end

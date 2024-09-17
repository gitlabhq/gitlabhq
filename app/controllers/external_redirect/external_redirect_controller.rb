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
          url: url_param,
          rel: relme_keywords
        }
      end
    end

    private

    def relme_keywords
      params['rel']&.strip
    end

    def url_param
      params['url']&.strip
    end

    def known_url?
      uri_data = Addressable::URI.parse(url_param)

      uri_data.site == Gitlab.config.gitlab.url
    end

    def should_handle_url?(url)
      # note: To avoid lots of redirects, don't allow url to point to self.
      ::Gitlab::UrlSanitizer.valid_web?(url) && !url.starts_with?(request.base_url + request.path)
    end

    def check_url_param
      render_404 unless should_handle_url?(url_param)
    end
  end
end

# frozen_string_literal: true

module UrlHelper
  def escaped_url(url)
    return unless url

    Addressable::URI.escape(url)
  rescue Addressable::URI::InvalidURIError
    nil
  end
end

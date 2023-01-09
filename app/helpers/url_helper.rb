# frozen_string_literal: true

module UrlHelper
  def escaped_url(url)
    Addressable::URI.escape(url)
  end
end

# frozen_string_literal: true

module FaviconHelper
  def favicon_extension_whitelist
    FaviconUploader::EXTENSION_WHITELIST
      .map { |extension| "'.#{extension}'"}
      .to_sentence
  end
end

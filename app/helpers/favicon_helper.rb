# frozen_string_literal: true

module FaviconHelper
  def favicon_extension_allowlist
    FaviconUploader::EXTENSION_ALLOWLIST
      .map { |extension| "'.#{extension}'" }
      .to_sentence
  end
end

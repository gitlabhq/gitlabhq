# frozen_string_literal: true

module AbuseReportsHelper
  def valid_image_mimetypes
    Gitlab::FileTypeDetection::SAFE_IMAGE_EXT
      .map { |extension| "image/#{extension}" }
      .to_sentence(last_word_connector: ' or ')
  end
end

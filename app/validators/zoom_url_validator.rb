# frozen_string_literal: true

# ZoomUrlValidator
#
# Custom validator for zoom urls
#
class ZoomUrlValidator < ActiveModel::EachValidator
  ALLOWED_SCHEMES = %w(https).freeze

  def validate_each(record, attribute, value)
    links_count = Gitlab::ZoomLinkExtractor.new(value).links.size
    valid = Gitlab::UrlSanitizer.valid?(value, allowed_schemes: ALLOWED_SCHEMES)

    return if links_count == 1 && valid

    record.errors.add(:url, 'must contain one valid Zoom URL')
  end
end

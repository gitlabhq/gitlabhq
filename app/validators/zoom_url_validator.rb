# frozen_string_literal: true

# ZoomUrlValidator
#
# Custom validator for zoom urls
#
class ZoomUrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if Gitlab::ZoomLinkExtractor.new(value).links.size == 1

    record.errors.add(:url, 'must contain one valid Zoom URL')
  end
end

# frozen_string_literal: true

# HtmlSafetyValidator
#
# Validates that a value does not contain HTML
# or other unsafe content that could lead to XSS.
# Relies on Rails HTML Sanitizer:
# https://github.com/rails/rails-html-sanitizer
#
# Example:
#
#   class Group < ActiveRecord::Base
#     validates :name, presence: true, html_safety: true
#   end
#
class HtmlSafetyValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank? || safe_value?(value)

    record.errors.add(attribute, self.class.error_message)
  end

  def self.error_message
    _("cannot contain HTML/XML tags, including any word between angle brackets (&lt;,&gt;).")
  end

  private

  # The `FullSanitizer` encodes ampersands as the HTML entity name.
  # This isn't particularly necessary for preventing XSS so the ampersand
  # is pre-encoded to avoid it being flagged in the comparison.
  def safe_value?(text)
    pre_encoded_text = text.gsub('&', '&amp;')
    Rails::Html::FullSanitizer.new.sanitize(pre_encoded_text) == pre_encoded_text
  end
end

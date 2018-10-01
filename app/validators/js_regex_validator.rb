# frozen_string_literal: true

class JsRegexValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return true if value.blank?

    parsed_regex = JsRegex.new(Regexp.new(value, Regexp::IGNORECASE))

    if parsed_regex.source.empty?
      record.errors.add(attribute, "Regex Pattern #{value} can not be expressed in Javascript")
    else
      parsed_regex.warnings.each { |warning| record.errors.add(attribute, warning) }
    end
  rescue RegexpError => regex_error
    record.errors.add(attribute, regex_error.to_s)
  end
end

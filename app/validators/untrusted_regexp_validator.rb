# frozen_string_literal: true

class UntrustedRegexpValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless value

    Gitlab::UntrustedRegexp.new(value)

  rescue RegexpError => e
    record.errors.add(attribute, "not valid RE2 syntax: #{e.message}")
  end
end

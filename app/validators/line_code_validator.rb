# frozen_string_literal: true

# LineCodeValidator
#
# Custom validator for GitLab line codes.
class LineCodeValidator < ActiveModel::EachValidator
  PATTERN = /\A[a-z0-9]+_\d+_\d+\z/

  def validate_each(record, attribute, value)
    unless PATTERN.match?(value)
      record.errors.add(attribute, "must be a valid line code")
    end
  end
end

# LineCodeValidator
#
# Custom validator for GitLab line codes.
class LineCodeValidator < ActiveModel::EachValidator
  PATTERN = /\A[a-z0-9]+_\d+_\d+\z/.freeze

  def validate_each(record, attribute, value)
    unless value =~ PATTERN
      record.errors.add(attribute, "must be a valid line code")
    end
  end
end

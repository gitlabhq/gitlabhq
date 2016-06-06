class RegexpValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, regexp_string)
    return if regexp_string.blank?

    Regexp.new(regexp_string)
  rescue RegexpError => e
    record.errors.add(attribute, "'#{regexp_string}' is not a valid regular expression: #{e.message}")
  end
end

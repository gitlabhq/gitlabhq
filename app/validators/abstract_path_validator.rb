class AbstractPathValidator < ActiveModel::EachValidator
  extend Gitlab::EncodingHelper

  def self.path_regex
    raise NotImplementedError
  end

  def self.format_regex
    raise NotImplementedError
  end

  def self.format_error_message
    raise NotImplementedError
  end

  def self.valid_path?(path)
    encode!(path)
    "#{path}/" =~ path_regex
  end

  def validate_each(record, attribute, value)
    unless value =~ self.class.format_regex
      record.errors.add(attribute, self.class.format_error_message)
      return
    end

    full_path = record.build_full_path
    return unless full_path

    unless self.class.valid_path?(full_path)
      record.errors.add(attribute, "#{value} is a reserved name")
    end
  end
end

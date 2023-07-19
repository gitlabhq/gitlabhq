# frozen_string_literal: true

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
    unless self.class.format_regex.match?(value)
      record.errors.add(attribute, self.class.format_error_message)
      return
    end

    if build_full_path_to_validate_against_reserved_names?
      path_to_validate_against_reserved_names = record.build_full_path
      return unless path_to_validate_against_reserved_names
    else
      path_to_validate_against_reserved_names = value
    end

    unless self.class.valid_path?(path_to_validate_against_reserved_names)
      record.errors.add(attribute, "#{value} is a reserved name")
    end
  end

  def build_full_path_to_validate_against_reserved_names?
    # By default, entities using the `Routable` concern can build full paths.
    # But entities like `Organization` do not have a parent, and hence cannot build full paths,
    # and this method can be overridden to return `false` in such cases.
    true
  end
end

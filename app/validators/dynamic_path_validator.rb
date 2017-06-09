# DynamicPathValidator
#
# Custom validator for GitLab path values.
# These paths are assigned to `Namespace` (& `Group` as a subclass) & `Project`
#
# Values are checked for formatting and exclusion from a list of illegal path
# names.
class DynamicPathValidator < ActiveModel::EachValidator
<<<<<<< HEAD
  class << self
    def valid_namespace_path?(path)
      "#{path}/" =~ Gitlab::Regex.full_namespace_path_regex
    end

    def valid_project_path?(path)
      "#{path}/" =~ Gitlab::Regex.full_project_path_regex
=======
  extend Gitlab::EncodingHelper

  class << self
    def valid_user_path?(path)
      encode!(path)
      "#{path}/" =~ Gitlab::PathRegex.root_namespace_path_regex
    end

    def valid_group_path?(path)
      encode!(path)
      "#{path}/" =~ Gitlab::PathRegex.full_namespace_path_regex
    end

    def valid_project_path?(path)
      encode!(path)
      "#{path}/" =~ Gitlab::PathRegex.full_project_path_regex
>>>>>>> abc61f260074663e5711d3814d9b7d301d07a259
    end
  end

  def path_valid_for_record?(record, value)
    full_path = record.respond_to?(:full_path) ? record.full_path : value

    return true unless full_path

    case record
    when Project
      self.class.valid_project_path?(full_path)
<<<<<<< HEAD
    else
      self.class.valid_namespace_path?(full_path)
=======
    when Group
      self.class.valid_group_path?(full_path)
    else # User or non-Group Namespace
      self.class.valid_user_path?(full_path)
>>>>>>> abc61f260074663e5711d3814d9b7d301d07a259
    end
  end

  def validate_each(record, attribute, value)
    unless value =~ Gitlab::PathRegex.namespace_format_regex
      record.errors.add(attribute, Gitlab::PathRegex.namespace_format_message)
      return
    end

    unless path_valid_for_record?(record, value)
      record.errors.add(attribute, "#{value} is a reserved name")
    end
  end
end

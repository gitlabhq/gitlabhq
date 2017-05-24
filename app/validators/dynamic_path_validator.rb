# DynamicPathValidator
#
# Custom validator for GitLab path values.
# These paths are assigned to `Namespace` (& `Group` as a subclass) & `Project`
#
# Values are checked for formatting and exclusion from a list of reserved path
# names.
class DynamicPathValidator < ActiveModel::EachValidator
  class << self
    def valid_namespace_path?(path)
      "#{path}/" =~ Gitlab::Regex.full_namespace_path_regex
    end

    def valid_project_path?(path)
      "#{path}/" =~ Gitlab::Regex.full_project_path_regex
    end
  end

  def path_valid_for_record?(record, value)
    full_path = record.respond_to?(:full_path) ? record.full_path : value

    return true unless full_path

    case record
    when Project
      self.class.valid_project_path?(full_path)
    else
      self.class.valid_namespace_path?(full_path)
    end
  end

  def validate_each(record, attribute, value)
    unless value =~ Gitlab::Regex.namespace_regex
      record.errors.add(attribute, Gitlab::Regex.namespace_regex_message)
      return
    end

    unless path_valid_for_record?(record, value)
      record.errors.add(attribute, "#{value} is a reserved name")
    end
  end
end

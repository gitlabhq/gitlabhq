# ProjectPathValidator
#
# Custom validator for GitLab project path values.
#
# Values are checked for formatting and exclusion from a list of reserved path
# names.
#
# This is basically the same as the `NamespaceValidator` but it skips the validation
# of the format with `Gitlab::Regex.namespace_regex`. The format of projects
# is validated in the class itself.
class ProjectPathValidator < NamespaceValidator
  def self.valid?(value)
    !reserved?(value)
  end

  def self.reserved?(value, type: :wildcard)
    super(value, type: :wildcard)
  end

  delegate :reserved?, to: :class

  def validate_each(record, attribute, value)
    if reserved?(value)
      record.errors.add(attribute, "#{value} is a reserved name")
    end
  end
end

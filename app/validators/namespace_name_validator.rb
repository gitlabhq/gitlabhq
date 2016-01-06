# NamespaceNameValidator
#
# Custom validator for GitLab namespace name strings.
class NamespaceNameValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value =~ Gitlab::Regex.namespace_name_regex
      record.errors.add(attribute, Gitlab::Regex.namespace_name_regex_message)
    end
  end
end

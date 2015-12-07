# NamespaceValidator
#
# Custom validator for GitLab namespace values.
#
# Values are checked for formatting and exclusion from `Gitlab::Blacklist.path`.
class NamespaceValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value =~ Gitlab::Regex.namespace_regex
      record.errors.add(attribute, Gitlab::Regex.namespace_regex_message)
    end

    if blacklisted?(value)
      record.errors.add(attribute, "#{value} is a reserved name")
    end
  end

  private

  def blacklisted?(value)
    Gitlab::Blacklist.path.include?(value)
  end
end

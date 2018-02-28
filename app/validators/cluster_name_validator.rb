# ClusterNameValidator
#
# Custom validator for ClusterName.
class ClusterNameValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if record.user?
      unless value.present?
        record.errors.add(attribute, " has to be present")
      end
    elsif record.gcp?
      if record.persisted? && record.name_changed?
        record.errors.add(attribute, " can not be changed because it's synchronized with provider")
      end

      unless value.length >= 1 && value.length <= 63
        record.errors.add(attribute, " is invalid syntax")
      end

      unless value =~ Gitlab::Regex.kubernetes_namespace_regex
        record.errors.add(attribute, Gitlab::Regex.kubernetes_namespace_regex_message)
      end
    end
  end
end

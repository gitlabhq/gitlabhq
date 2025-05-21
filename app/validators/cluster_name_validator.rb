# frozen_string_literal: true

# ClusterNameValidator
#
# Custom validator for ClusterName.
class ClusterNameValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if record.provided_by_user?
      if value.blank?
        record.errors.add(attribute, 'has to be present')
      elsif record.name_changed? && value.length > 2048
        record.errors.add(attribute, 'is too long')
      end
    else
      if record.persisted? && record.name_changed?
        record.errors.add(attribute, "can not be changed because it's synchronized with provider")
      end

      unless value.length >= 1 && value.length <= 63
        record.errors.add(attribute, 'syntax is invalid')
      end

      unless Gitlab::Regex.kubernetes_namespace_regex.match(value)
        record.errors.add(attribute, Gitlab::Regex.kubernetes_namespace_regex_message)
      end
    end
  end
end

# VariableDuplicatesValidator
#
# This validator is designed for especially the following condition
# - Use `accepts_nested_attributes_for :xxx` in a parent model
# - Use `validates :xxx, uniqueness: { scope: :xxx_id }` in a child model
class VariableDuplicatesValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if record.errors.include?(:"#{attribute}.key")

    if options[:scope]
      scoped = value.group_by do |variable|
        Array(options[:scope]).map { |attr| variable.send(attr) } # rubocop:disable GitlabSecurity/PublicSend
      end
      scoped.each_value { |scope| validate_duplicates(record, attribute, scope) }
    else
      validate_duplicates(record, attribute, value)
    end
  end

  private

  def validate_duplicates(record, attribute, values)
    duplicates = values.reject(&:marked_for_destruction?).group_by(&:key).select { |_, v| v.many? }.map(&:first)
    if duplicates.any?
      error_message = "have duplicate values (#{duplicates.join(", ")})"
      error_message += " for #{values.first.send(options[:scope])} scope" if options[:scope] # rubocop:disable GitlabSecurity/PublicSend
      record.errors.add(attribute, error_message)
    end
  end
end

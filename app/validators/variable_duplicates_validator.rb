# VariableDuplicatesValidator
#
# This validtor is designed for especially the following condition
# - Use `accepts_nested_attributes_for :xxx` in a parent model
# - Use `validates :xxx, uniqueness: { scope: :xxx_id }` in a child model
class VariableDuplicatesValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    puts "#{self.class.name} - #{__callee__}: value: #{value.map{ |v| [v.id, v.key, v.value, v.marked_for_destruction?]}}"
    duplicates = value.reject(&:marked_for_destruction?).group_by(&:key).select { |_, v| v.many? }.map(&:first)
    if duplicates.any?
      record.errors.add(attribute, "Duplicate variables: #{duplicates.join(", ")}")
    end
  end
end

# frozen_string_literal: true

# NestedAttributesDuplicates
#
# This validator is designed for especially the following condition
# - Use `accepts_nested_attributes_for :xxx` in a parent model
# - Use `validates :xxx, uniqueness: { scope: :xxx_id }` in a child model
class NestedAttributesDuplicatesValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if child_attributes.any? { |child_attribute| record.errors.include?(:"#{attribute}.#{child_attribute}") }

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

  # rubocop: disable CodeReuse/ActiveRecord
  def validate_duplicates(record, attribute, values)
    child_attributes.each do |child_attribute|
      duplicates = values.reject(&:marked_for_destruction?).group_by(&:"#{child_attribute}").select { |_, v| v.many? }.map(&:first)
      next unless duplicates.any?

      error_message = "have duplicate values (#{duplicates.join(', ')})"
      error_message << " for #{values.first.send(options[:scope])} scope" if options[:scope] # rubocop:disable GitlabSecurity/PublicSend
      record.errors.add(attribute, error_message)
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def child_attributes
    options[:child_attributes] || %i[key]
  end
end

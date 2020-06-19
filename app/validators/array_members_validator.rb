# frozen_string_literal: true

# ArrayMembersValidator
#
# Custom validator that checks if validated
# attribute contains non empty array, which every
# element is an instances of :member_class
#
# Example:
#
#   class Config::Root < ActiveRecord::Base
#     validates :nodes, member_class: Config::Node
#   end
#
class ArrayMembersValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if !value.is_a?(Array) || value.empty? || value.any? { |child| !child.instance_of?(options[:member_class]) }
      record.errors.add(attribute, _("should be an array of %{object_name} objects") % { object_name: options.fetch(:object_name, attribute) })
    end
  end
end

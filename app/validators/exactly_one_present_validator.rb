# frozen_string_literal: true

# ExactlyOnePresentValidator
#
# Custom validator for ensuring that exactly one of the specified fields or associations is present.
#
# Options:
# - :fields - Array, Symbol, or Proc for database columns and custom methods.
#             Uses the reader method (public_send) to get the value, so any custom
#             getter definition will be used.
# - :associations - Array, Symbol, or Proc for ActiveRecord associations.
#                   Uses ActiveRecord's association reflection to get the value directly,
#                   bypassing any custom reader methods.
# - :error_key - Symbol for the error key (default: :base)
# - :message - String or Proc for custom error message
#
# At least one of :fields or :associations must be provided. Both can be used together.
#
# The validator supports three types of values for :fields and :associations:
# - Array: Static list of field/association names
# - Symbol: Method name that returns an array of field/association names
# - Proc/lambda: Dynamic resolution executed in the record's context
#
# Examples:
#
#   # Using :fields with an Array (database columns and custom methods)
#   class MyModel < ApplicationRecord
#     validates_with ExactlyOnePresentValidator, fields: %i[name url identifier]
#   end
#
#   # Using :associations with an Array (ActiveRecord associations)
#   class MyModel < ApplicationRecord
#     belongs_to :project, optional: true
#     belongs_to :group, optional: true
#     validates_with ExactlyOnePresentValidator, associations: %i[project group]
#   end
#
#   # Combining :fields and :associations
#   class MyModel < ApplicationRecord
#     belongs_to :custom_status, optional: true
#     validates_with ExactlyOnePresentValidator,
#       fields: %i[system_defined_status],
#       associations: %i[custom_status]
#
#     def system_defined_status
#       @system_defined_status ||= SystemStatus.find_by(id: system_status_id)
#     end
#   end
#
#   # Using a Symbol to call a method that returns fields dynamically
#   class MyModel < ApplicationRecord
#     validates_with ExactlyOnePresentValidator, fields: :dynamic_fields
#
#     def dynamic_fields
#       some_condition? ? %i[field_a field_b] : %i[field_c field_d]
#     end
#   end
#
#   # Using a Proc/lambda for dynamic field resolution
#   class MyModel < ApplicationRecord
#     validates_with ExactlyOnePresentValidator, fields: -> {
#       self.type == 'TypeA' ? %i[field_a field_b] : %i[field_c field_d]
#     }
#   end
#
#   # Using custom error key and message
#   class MyModel < ApplicationRecord
#     validates_with ExactlyOnePresentValidator,
#       fields: %i[name url],
#       associations: %i[project],
#       error_key: :custom_key,
#       message: 'Please provide exactly one identifier'
#   end
class ExactlyOnePresentValidator < ActiveModel::Validator # rubocop:disable Gitlab/BoundedContexts,Gitlab/NamespacedClass -- Validators can belong to multiple bounded contexts
  def initialize(*args)
    super

    return unless options[:fields].blank? && options[:associations].blank?

    raise 'ExactlyOnePresentValidator: :fields or :associations options are required'
  end

  def validate(record)
    resolved_fields = resolve_option(record, :fields)
    resolved_associations = resolve_option(record, :associations)
    all_keys = resolved_fields + resolved_associations

    present_values = present_field_values(record, resolved_fields) +
      present_association_values(record, resolved_associations)

    return if present_values.one?

    add_validation_error(record, all_keys)
  end

  private

  def resolve_option(record, option_name)
    option_value = options[option_name]

    case option_value
    when NilClass
      []
    when Array
      option_value
    when Symbol
      unless record.respond_to?(option_value, true)
        raise ArgumentError, "Unknown :#{option_name} method #{option_value}"
      end

      Array(record.send(option_value)) # rubocop:disable GitlabSecurity/PublicSend -- option_value comes from the class definition, not runtime values
    when Proc
      Array(record.instance_exec(&option_value))
    else
      raise ArgumentError, "Unknown :#{option_name} option type #{option_value.class}"
    end
  end

  def present_field_values(record, fields)
    fields.filter_map do |field|
      record.public_send(field.to_sym).presence # rubocop:disable GitlabSecurity/PublicSend -- field comes from class definition
    end
  end

  def present_association_values(record, associations)
    associations.filter_map { |assoc| record.association(assoc.to_sym).reader }
  end

  def add_validation_error(record, all_keys)
    error_key = options[:error_key] || :base
    record.errors.add(error_key.to_sym, build_error_message(all_keys))
  end

  def build_error_message(all_keys)
    return options[:message].call(all_keys) if options[:message].respond_to?(:call)

    options[:message] || format(_("Exactly one of %{fields} must be present"), fields: all_keys.join(', '))
  end
end

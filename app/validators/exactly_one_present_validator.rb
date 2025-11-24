# frozen_string_literal: true

# ExactlyOnePresentValidator
#
# Custom validator for ensuring that exactly one of the specified fields is present.
#
# Examples:
#
#   # Using an Array of field names (static fields)
#   class MyModel < ApplicationRecord
#     belongs_to :relation, optional: true
#     validates_with ExactlyOnePresentValidator, fields: %i[relation name url]
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
#     validates_with ExactlyOnePresentValidator, fields: ->(record) {
#       record.type == 'TypeA' ? %i[field_a field_b] : %i[field_c field_d]
#     }
#   end
#
#   # Using custom error key and message
#   class MyModel < ApplicationRecord
#     validates_with ExactlyOnePresentValidator,
#       fields: %i[relation name url],
#       error_key: :custom_key,
#       message: 'Please provide exactly one identifier'
#   end
class ExactlyOnePresentValidator < ActiveModel::Validator # rubocop:disable Gitlab/BoundedContexts,Gitlab/NamespacedClass -- Validators can belong to multiple bounded contexts
  def initialize(*args)
    super

    raise 'ExactlyOnePresentValidator: :fields options are required' if options[:fields].blank?
  end

  def validate(record)
    fields = resolve_fields(record)
    present_values = present_field_values(record, fields)

    return if present_values.one?

    add_validation_error(record, fields)
  end

  private

  def resolve_fields(record)
    option_fields = options[:fields]
    case option_fields
    when Symbol
      raise ArgumentError, "Unknown :fields method #{option_fields}" unless record.respond_to?(option_fields, true)

      Array(record.send(option_fields)) # rubocop:disable GitlabSecurity/PublicSend -- options_fields comes from the class definition, not runtime values
    when Proc
      Array(record.instance_exec(&option_fields))
    when Array
      option_fields
    else
      raise ArgumentError, "Unknown :fields option type #{option_fields.class}"
    end
  end

  def present_field_values(record, fields)
    fields.filter_map do |field|
      symbol_field = field.to_sym

      if record.class.reflect_on_association(symbol_field)
        record.association(symbol_field).reader
      else
        record[symbol_field].presence
      end
    end
  end

  def add_validation_error(record, fields)
    error_key = options[:error_key] || :base
    error_message = build_error_message(fields)

    record.errors.add(error_key.to_sym, error_message)
  end

  def build_error_message(fields)
    if options[:message].respond_to?(:call)
      options[:message].call(fields)
    else
      options[:message] || format(_("Exactly one of %{fields} must be present"), fields: fields.join(', '))
    end
  end
end

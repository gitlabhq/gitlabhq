# frozen_string_literal: true

# ExactlyOnePresentValidator
#
# Custom validator for ensuring that exactly one of the specified fields is present.
#
# Example:
#
#   class MyModel < ApplicationRecord
#     belongs_to :relation, optional: true
#     validates_with ExactlyOnePresentValidator, fields: %w[relation name url]
#   end
class ExactlyOnePresentValidator < ActiveModel::Validator # rubocop:disable Gitlab/BoundedContexts,Gitlab/NamespacedClass -- Validators can belong to multiple bounded contexts
  def initialize(*args)
    super

    raise 'ExactlyOnePresentValidator: :fields options are required' if options[:fields].blank?
  end

  def validate(record)
    fields = options[:fields]
    values = fields.filter_map do |field|
      symbol_field = field.to_sym
      if record.class.reflect_on_association(symbol_field)
        record.association(symbol_field).reader
      else
        record[symbol_field].presence
      end
    end

    return if values.one?

    error_key = options[:error_key] || :base
    error_message = if options[:message].respond_to?(:call)
                      options[:message].call(fields)
                    else
                      options[:message] ||
                        format(_("Exactly one of %{fields} must be present"), fields: fields.join(', '))
                    end

    record.errors.add(error_key.to_sym, error_message)
  end
end

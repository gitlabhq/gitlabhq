# frozen_string_literal: true
#
# JsonSchemaValidator
#
# Custom validator for json schema.
# Create a json schema within the json_schemas directory
#
#   class Project < ActiveRecord::Base
#     validates :data, json_schema: { filename: "file" }
#   end
#
class JsonSchemaValidator < ActiveModel::EachValidator
  def initialize(options)
    raise ArgumentError, "Expected 'filename' as an argument" unless options[:filename]

    super(options)
  end

  def validate_each(record, attribute, value)
    unless valid_schema?(value)
      record.errors.add(attribute, "must be a valid json schema")
    end
  end

  private

  def valid_schema?(value)
    JSON::Validator.validate(schema_path, value)
  end

  def schema_path
    Rails.root.join('app', 'validators', 'json_schemas', "#{options[:filename]}.json").to_s
  end
end

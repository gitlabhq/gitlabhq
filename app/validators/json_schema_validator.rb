# frozen_string_literal: true

#
# JsonSchemaValidator
#
# Custom validator for json schema.
# Create a json schema within the json_schemas directory
#
#   class Project < ActiveRecord::Base
#     validates :data, json_schema: { filename: "file", size_limit: 64.kilobytes }
#   end
#
class JsonSchemaValidator < ActiveModel::EachValidator
  FILENAME_ALLOWED = /\A[a-z0-9_-]*\Z/
  FilenameError = Class.new(StandardError)
  BASE_DIRECTORY = %w[app validators json_schemas].freeze

  def initialize(options)
    raise ArgumentError, "Expected 'filename' as an argument" unless options[:filename]
    raise FilenameError, "Must be a valid 'filename'" unless options[:filename].match?(FILENAME_ALLOWED)

    @base_directory = options.delete(:base_directory) || BASE_DIRECTORY
    @size_limit = options.delete(:size_limit)

    super(options)
  end

  def validate_each(record, attribute, value)
    value = Gitlab::Json.parse(Gitlab::Json.dump(value)) if options[:hash_conversion] == true
    value = Gitlab::Json.parse(value.to_s) if options[:parse_json] == true && !value.nil?

    if size_limit && !valid_size?(value)
      record.errors.add(attribute, size_error_message)
      return
    end

    if options[:detail_errors]
      schema.validate(value).each do |error|
        message = format_error_message(error)
        record.errors.add(attribute, message)
      end
    else
      record.errors.add(attribute, error_message) unless valid_schema?(value)
    end
  end

  def schema
    @schema ||= JSONSchemer.schema(Pathname.new(schema_path))
  end

  private

  attr_reader :base_directory, :size_limit

  def valid_size?(value)
    json_size(value) <= size_limit
  end

  def json_size(value)
    Gitlab::Json.dump(value).bytesize
  end

  def size_error_message
    human_size = ActiveSupport::NumberHelper.number_to_human_size(size_limit)
    format(_("is too large. Maximum size allowed is %{size}"), size: human_size)
  end

  def format_error_message(error)
    case error['type']
    when 'oneOf'
      format_one_of_error(error)
    else
      error['error']
    end
  end

  def format_one_of_error(error)
    schema_options = error['schema']['oneOf']
    required_props = schema_options.flat_map { |option| option['required'] }.uniq

    message = if error['root_schema']['type'] == 'array'
                _("value at %{data_pointer} should use only one of: %{requirements}")
              else
                _("should use only one of: %{requirements}")
              end

    format(
      message,
      requirements: required_props.join(', '),
      data_pointer: error['data_pointer']
    )
  end

  def valid_schema?(value)
    schema.valid?(value)
  end

  def schema_path
    @schema_path ||= Rails.root.join(*base_directory, filename_with_extension).to_s
  end

  def filename_with_extension
    "#{options[:filename]}.json"
  end

  def error_message
    options[:message] || _('must be a valid json schema')
  end
end

JsonSchemaValidator.prepend_mod

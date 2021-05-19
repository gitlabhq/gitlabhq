# frozen_string_literal: true

class FileSizeValidator < ActiveModel::EachValidator
  MESSAGES = { is: :wrong_size, minimum: :size_too_small, maximum: :size_too_big }.freeze
  CHECKS   = { is: :==, minimum: :>=, maximum: :<= }.freeze

  DEFAULT_TOKENIZER = -> (value) { value.split(//) }.freeze
  RESERVED_OPTIONS  = [:minimum, :maximum, :within, :is, :tokenizer, :too_short, :too_long].freeze

  def initialize(options)
    if range = (options.delete(:in) || options.delete(:within))
      raise ArgumentError, ":in and :within must be a Range" unless range.is_a?(Range)

      options[:minimum] = range.begin
      options[:maximum] = range.end
      options[:maximum] -= 1 if range.exclude_end?
    end

    super
  end

  def check_validity!
    keys = CHECKS.keys & options.keys

    if keys.empty?
      raise ArgumentError, 'Range unspecified. Specify the :within, :maximum, :minimum, or :is option.'
    end

    keys.each do |key|
      value = options[key]

      unless (value.is_a?(Integer) && value >= 0) || value.is_a?(Symbol)
        raise ArgumentError, ":#{key} must be a nonnegative Integer or symbol"
      end
    end
  end

  def validate_each(record, attribute, value)
    raise(ArgumentError, "A CarrierWave::Uploader::Base object was expected") unless value.is_a? CarrierWave::Uploader::Base

    value = (options[:tokenizer] || DEFAULT_TOKENIZER).call(value) if value.is_a?(String)

    CHECKS.each do |key, validity_check|
      next unless check_value = options[key]

      check_value =
        case check_value
        when Integer
          check_value
        when Symbol
          record.public_send(check_value) # rubocop:disable GitlabSecurity/PublicSend
        end

      value ||= [] if key == :maximum

      value_size = value.size
      next if value_size.public_send(validity_check, check_value) # rubocop:disable GitlabSecurity/PublicSend

      errors_options = options.except(*RESERVED_OPTIONS)
      errors_options[:file_size] = help.number_to_human_size check_value

      default_message = options[MESSAGES[key]]
      errors_options[:message] ||= default_message if default_message

      record.errors.add(attribute, MESSAGES[key], **errors_options)
    end
  end

  def help
    Helper.instance
  end

  class Helper
    include Singleton
    include ActionView::Helpers::NumberHelper
  end
end

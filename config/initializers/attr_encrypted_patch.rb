# frozen_string_literal: true

if Gem::Version.new(AttrEncrypted::Version.string) > "4.2.0"
  raise 'New version of AttrEncrypted detected, please remove or update this patch'
end

module AttrEncrypted
  module Adapters
    module ActiveRecord
      module InstanceMethodsPatch
        # Prevent attr_encrypted from defining virtual accessors for encryption
        # data when the code and schema are out of sync. See this issue for more
        # details: https://github.com/attr-encrypted/attr_encrypted/issues/332
        def attribute_instance_methods_as_symbols_available?
          false
        end
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  extend AttrEncrypted::Adapters::ActiveRecord::InstanceMethodsPatch
end

# We monkey-patch to prevent `attribute_instance_methods_as_symbols` from being called
# https://github.com/attr-encrypted/attr_encrypted/pull/468
AttrEncrypted.class_eval do
  # rubocop:disable Metrics/AbcSize -- This is upstream code
  # rubocop:disable Metrics/CyclomaticComplexity -- This is upstream code
  # rubocop:disable Metrics/PerceivedComplexity -- This is upstream code
  def attr_encrypted(*attributes)
    options = attributes.last.is_a?(Hash) ? attributes.pop : {}
    options = attr_encrypted_default_options.dup.merge!(attr_encrypted_options).merge!(options)

    options[:encode] = options[:default_encoding] if options[:encode] == true
    options[:encode_iv] = options[:default_encoding] if options[:encode_iv] == true
    options[:encode_salt] = options[:default_encoding] if options[:encode_salt] == true

    attributes.each do |attribute|
      encrypted_attribute_name = (options[:attribute] || [options[:prefix], attribute,
        options[:suffix]].join).to_sym

      if attribute_instance_methods_as_symbols_available?
        instance_methods_as_symbols = attribute_instance_methods_as_symbols

        attr_reader encrypted_attribute_name unless instance_methods_as_symbols.include?(encrypted_attribute_name)

        unless instance_methods_as_symbols.include?(:"#{encrypted_attribute_name}=")
          attr_writer encrypted_attribute_name
        end

        iv_name = :"#{encrypted_attribute_name}_iv"
        attr_reader iv_name unless instance_methods_as_symbols.include?(iv_name)
        attr_writer iv_name unless instance_methods_as_symbols.include?(:"#{iv_name}=")

        salt_name = :"#{encrypted_attribute_name}_salt"
        attr_reader salt_name unless instance_methods_as_symbols.include?(salt_name)
        attr_writer salt_name unless instance_methods_as_symbols.include?(:"#{salt_name}=")
      end

      define_method(attribute) do
        instance_variable_get(:"@#{attribute}") || instance_variable_set(:"@#{attribute}",
          attr_encrypted_decrypt(attribute, send(encrypted_attribute_name)))
      end

      define_method(:"#{attribute}=") do |value|
        send(:"#{encrypted_attribute_name}=", attr_encrypted_encrypt(attribute, value))
        instance_variable_set(:"@#{attribute}", value)
      end

      define_method(:"#{attribute}?") do
        value = send(attribute)
        value.respond_to?(:empty?) ? !value.empty? : !!value
      end

      attr_encrypted_encrypted_attributes[attribute.to_sym] = options.merge(attribute: encrypted_attribute_name)
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity
end

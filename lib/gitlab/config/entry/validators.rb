# frozen_string_literal: true

module Gitlab
  module Config
    module Entry
      module Validators
        class AllowedKeysValidator < ActiveModel::EachValidator
          def validate_each(record, attribute, value)
            unknown_keys = value.try(:keys).to_a - options[:in]

            if unknown_keys.any?
              record.errors.add(attribute, "contains unknown keys: " +
                                            unknown_keys.join(', '))
            end
          end
        end

        class DisallowedKeysValidator < ActiveModel::EachValidator
          def validate_each(record, attribute, value)
            present_keys = value.try(:keys).to_a & options[:in]

            if present_keys.any?
              record.errors.add(attribute, "contains disallowed keys: " +
                present_keys.join(', '))
            end
          end
        end

        class RequiredKeysValidator < ActiveModel::EachValidator
          def validate_each(record, attribute, value)
            present_keys = options[:in] - value.try(:keys).to_a

            if present_keys.any?
              record.errors.add(attribute, "missing required keys: " +
                present_keys.join(', '))
            end
          end
        end

        class AllowedValuesValidator < ActiveModel::EachValidator
          def validate_each(record, attribute, value)
            unless options[:in].include?(value.to_s)
              record.errors.add(attribute, "unknown value: #{value}")
            end
          end
        end

        class AllowedArrayValuesValidator < ActiveModel::EachValidator
          def validate_each(record, attribute, value)
            unknown_values = value - options[:in]
            unless unknown_values.empty?
              record.errors.add(attribute, "contains unknown values: " +
                                            unknown_values.join(', '))
            end
          end
        end

        class ArrayOfStringsValidator < ActiveModel::EachValidator
          include LegacyValidationHelpers

          def validate_each(record, attribute, value)
            unless validate_array_of_strings(value)
              record.errors.add(attribute, 'should be an array of strings')
            end
          end
        end

        class ArrayOrStringValidator < ActiveModel::EachValidator
          def validate_each(record, attribute, value)
            unless value.is_a?(Array) || value.is_a?(String)
              record.errors.add(attribute, 'should be an array or a string')
            end
          end
        end

        class BooleanValidator < ActiveModel::EachValidator
          include LegacyValidationHelpers

          def validate_each(record, attribute, value)
            unless validate_boolean(value)
              record.errors.add(attribute, 'should be a boolean value')
            end
          end
        end

        class DurationValidator < ActiveModel::EachValidator
          include LegacyValidationHelpers

          def validate_each(record, attribute, value)
            unless validate_duration(value)
              record.errors.add(attribute, 'should be a duration')
            end

            if options[:limit]
              unless validate_duration_limit(value, options[:limit])
                record.errors.add(attribute, 'should not exceed the limit')
              end
            end
          end
        end

        class HashOrStringValidator < ActiveModel::EachValidator
          def validate_each(record, attribute, value)
            unless value.is_a?(Hash) || value.is_a?(String)
              record.errors.add(attribute, 'should be a hash or a string')
            end
          end
        end

        class HashOrIntegerValidator < ActiveModel::EachValidator
          def validate_each(record, attribute, value)
            unless value.is_a?(Hash) || value.is_a?(Integer)
              record.errors.add(attribute, 'should be a hash or an integer')
            end
          end
        end

        class KeyValidator < ActiveModel::EachValidator
          include LegacyValidationHelpers

          def validate_each(record, attribute, value)
            if validate_string(value)
              validate_path(record, attribute, value)
            else
              record.errors.add(attribute, 'should be a string or symbol')
            end
          end

          private

          def validate_path(record, attribute, value)
            path = CGI.unescape(value.to_s)

            if path.include?('/')
              record.errors.add(attribute, 'cannot contain the "/" character')
            elsif path == '.' || path == '..'
              record.errors.add(attribute, 'cannot be "." or ".."')
            end
          end
        end

        class RegexpValidator < ActiveModel::EachValidator
          include LegacyValidationHelpers

          def validate_each(record, attribute, value)
            unless validate_regexp(value)
              record.errors.add(attribute, 'must be a regular expression')
            end
          end

          protected

          def fallback
            false
          end

          private

          def matches_syntax?(value)
            Gitlab::UntrustedRegexp::RubySyntax.matches_syntax?(value)
          end

          def validate_regexp(value)
            matches_syntax?(value) &&
              Gitlab::UntrustedRegexp::RubySyntax.valid?(value, fallback: fallback)
          end
        end

        class ArrayOfStringsOrRegexpsValidator < RegexpValidator
          def validate_each(record, attribute, value)
            unless validate_array_of_strings_or_regexps(value)
              record.errors.add(attribute, 'should be an array of strings or regexps')
            end
          end

          private

          def validate_array_of_strings_or_regexps(values)
            values.is_a?(Array) && values.all?(&method(:validate_string_or_regexp))
          end

          def validate_string_or_regexp(value)
            return false unless value.is_a?(String)
            return validate_regexp(value) if matches_syntax?(value)

            true
          end
        end

        class ArrayOfStringsOrRegexpsWithFallbackValidator < ArrayOfStringsOrRegexpsValidator
          protected

          def fallback
            true
          end
        end

        class ArrayOfStringsOrStringValidator < RegexpValidator
          def validate_each(record, attribute, value)
            unless validate_array_of_strings_or_string(value)
              record.errors.add(attribute, 'should be an array of strings or a string')
            end
          end

          private

          def validate_array_of_strings_or_string(values)
            validate_array_of_strings(values) || validate_string(values)
          end
        end

        class TypeValidator < ActiveModel::EachValidator
          def validate_each(record, attribute, value)
            type = options[:with]
            raise unless type.is_a?(Class)

            unless value.is_a?(type)
              message = options[:message] || "should be a #{type.name}"
              record.errors.add(attribute, message)
            end
          end
        end

        class VariablesValidator < ActiveModel::EachValidator
          include LegacyValidationHelpers

          def validate_each(record, attribute, value)
            unless validate_variables(value)
              record.errors.add(attribute, 'should be a hash of key value pairs')
            end
          end
        end

        class PortNamePresentAndUniqueValidator < ActiveModel::EachValidator
          def validate_each(record, attribute, value)
            return unless value.is_a?(Array)

            ports_size = value.count
            return if ports_size <= 1

            named_ports = value.select { |e| e.is_a?(Hash) }.map { |e| e[:name] }.compact.map(&:downcase)

            if ports_size != named_ports.size
              record.errors.add(attribute, 'when there is more than one port, a unique name should be added')
            end

            if ports_size != named_ports.uniq.size
              record.errors.add(attribute, 'each port name must be different')
            end
          end
        end

        class PortUniqueValidator < ActiveModel::EachValidator
          def validate_each(record, attribute, value)
            value = ports(value)
            return unless value.is_a?(Array)

            ports_size = value.count
            return if ports_size <= 1

            if transform_ports(value).size != ports_size
              record.errors.add(attribute, 'each port number can only be referenced once')
            end
          end

          private

          def ports(current_data)
            current_data
          end

          def transform_ports(raw_ports)
            raw_ports.map do |port|
              case port
              when Integer
                port
              when Hash
                port[:number]
              end
            end.uniq
          end
        end

        class JobPortUniqueValidator < PortUniqueValidator
          private

          def ports(current_data)
            return unless current_data.is_a?(Hash)

            (image_ports(current_data) + services_ports(current_data)).compact
          end

          def image_ports(current_data)
            return [] unless current_data[:image].is_a?(Hash)

            current_data.dig(:image, :ports).to_a
          end

          def services_ports(current_data)
            current_data.dig(:services).to_a.flat_map { |service| service.is_a?(Hash) ? service[:ports] : nil }
          end
        end

        class ServicesWithPortsAliasUniqueValidator < ActiveModel::EachValidator
          def validate_each(record, attribute, value)
            current_aliases = aliases(value)
            return if current_aliases.empty?

            unless aliases_unique?(current_aliases)
              record.errors.add(:config, 'alias must be unique in services with ports')
            end
          end

          private

          def aliases(value)
            value.select { |s| s.is_a?(Hash) && s[:ports] }.pluck(:alias) # rubocop:disable CodeReuse/ActiveRecord
          end

          def aliases_unique?(aliases)
            aliases.size == aliases.uniq.size
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module RemoteDevelopment
      # rubocop:disable Migration/BatchedMigrationBaseClass -- This is not a migration file class so we do not need to inherit from BatchedMigrationJob
      class BmDesiredConfigArrayValidator < ActiveModel::EachValidator
        EXPECTED_SEQUENCE = [
          { kind: "ConfigMap", name_pattern: /workspace-inventory$/ },
          { kind: "Deployment", name_pattern: /.*/ },
          { kind: "Service", name_pattern: /.*/ },
          { kind: "PersistentVolumeClaim", name_pattern: /.*/ },
          { kind: "ServiceAccount", name_pattern: /.*/ },
          { kind: "NetworkPolicy", name_pattern: /.*/ },
          { kind: "ConfigMap", name_pattern: /scripts-configmap$/ },
          { kind: "ConfigMap", name_pattern: /secrets-inventory$/ },
          { kind: "ResourceQuota", name_pattern: /.*/ },
          { kind: "Secret", name_pattern: /env-var$/ },
          { kind: "Secret", name_pattern: /file$/ }
        ].freeze

        # @param [RemoteDevelopment::DesiredConfig] record
        # @param [Symbol] attribute
        # @param [Array] value
        # @return [void] The result is stored in the errors param
        def validate_each(record, attribute, value)
          unless value.is_a?(Array)
            record.errors.add(attribute, "must be an array")
            return
          end

          if value.empty?
            record.errors.add(attribute, "must not be empty")
            return
          end

          value = value.map(&:deep_symbolize_keys)
          normalized_expected_array = normalize_expected_order(value)
          normalized_config_array = value.map do |item|
            item => {
              kind: String => item_kind,
              metadata: {
                name: String => item_name
              },
              **
            }

            "#{item_kind}/#{item_name}"
          end

          validate_order(normalized_config_array, normalized_expected_array, record.errors, attribute)
        end

        private

        # @param [Array] normalized_config_array
        # @param [Array] normalized_expected_array
        # @param [ActiveModel::Errors] errors - stores the validation results
        # @param [Symbol] attribute_symbol - symbol of the attribute associated with the error
        # @return [Void]
        def validate_order(normalized_config_array, normalized_expected_array, errors, attribute_symbol)
          normalized_config_array.each_with_index do |item, index|
            expected_index = normalized_expected_array.index(item)

            if expected_index.nil?
              errors.add(attribute_symbol, "item #{item} at index #{index} is unexpected")
              next
            end

            next if expected_index == index

            errors.add(attribute_symbol, "item #{item} at index #{index} must be at #{expected_index}")
          end
        end

        # This method normalizes the expected order of items based on the config array
        # It creates a mapping of expected positions for each kind/name combination
        #
        # @param [Array] config_array The array of configuration items to normalize
        # @return [Array] An array with expected order of items
        def normalize_expected_order(config_array)
          expected_positions = []

          EXPECTED_SEQUENCE.each_with_index do |expected, _|
            config_array.each do |item|
              item => {
                kind: String => item_kind,
                metadata: {
                  name: String => item_name
                }
              }

              expected_positions << "#{item_kind}/#{item_name}" if matches?(item_kind, item_name, expected)
            end
          end

          expected_positions
        end

        # Validates if the given configuration matches the expected value
        #
        # @param [String] kind The type of configuration to validate
        # @param [String] name The name of the configuration item
        # @param [Object] expected The expected value to match against. See {#EXPECTED_SEQUENCE} above.
        # @return [Boolean] Returns true if the configuration matches the expected value, false otherwise
        def matches?(kind, name, expected)
          kind == expected[:kind] && expected[:name_pattern].match?(name)
        end
      end

      # rubocop:enable Migration/BatchedMigrationBaseClass
    end
  end
end

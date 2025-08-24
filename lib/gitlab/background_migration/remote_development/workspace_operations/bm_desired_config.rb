# frozen_string_literal: true

require "hashdiff"

module Gitlab
  module BackgroundMigration
    module RemoteDevelopment
      module WorkspaceOperations
        class BmDesiredConfig # rubocop:disable Migration/BatchedMigrationBaseClass -- This is not a migration file class so we do not need to inherit from BatchedMigrationJob
          include ActiveModel::Model
          include ActiveModel::Attributes
          include ActiveModel::Validations
          include ActiveModel::Serialization
          include ActiveModel::Serializers::JSON

          # @!attribute [rw] desired_config_array
          #   @return [Array]
          attribute :desired_config_array

          validates :desired_config_array, presence: true, json_schema: {
            filename: 'workspaces_kubernetes',
            detail_errors: true,
            size_limit: 64.kilobytes
          }
          validate :desired_config_validator

          # @param [BmDesiredConfig] other
          # @return [Boolean]
          def ==(other)
            return false unless other.is_a?(self.class)
            return true if equal?(other)

            desired_config_array == other.desired_config_array
          end

          # @param [BmDesiredConfig] other
          # @return [Array]
          def diff(other)
            raise ArgumentError, "Expected #{self.class}, got #{other.class}" unless other.is_a?(self.class)

            # we do not want to calculate diff using the longest common subsequence
            # because we want to catch changes at the index of self rather than find
            # the common elements between the two arrays. This example should help explain
            # the difference https://github.com/liufengyun/hashdiff/issues/43#issuecomment-485497196
            # noinspection RubyMismatchedArgumentType -- hashdiff also supports arrays
            Hashdiff.diff(desired_config_array, other.desired_config_array, use_lcs: false)
          end

          # @return [Object]
          def desired_config_validator
            validator = BmDesiredConfigArrayValidator.new(attributes: [:desired_config_array])
            validator.validate_each(self, :desired_config_array, desired_config_array)
          end

          # @return [Array]
          def symbolized_desired_config_array
            as_json.fetch("desired_config_array").map(&:deep_symbolize_keys)
          end
        end
      end
    end
  end
end

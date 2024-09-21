# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Context
        class OmnibusConfig
          extend Forwardable

          def_delegators :@config,
            :count,
            :deep_stringify_keys,
            :deep_symbolize_keys,
            :default_proc,
            :dig,
            :each_key,
            :each_pair,
            :each_value,
            :each,
            :empty?,
            :fetch_values,
            :fetch,
            :filter,
            :keys,
            :length,
            :map,
            :member?,
            :merge,
            :reject,
            :select,
            :size,
            :slice,
            :stringify_keys,
            :symbolize_keys,
            :transform_keys,
            :transform_values,
            :value?,
            :values_at,
            :values,
            :[]

          # @param [String|Pathname] source
          def initialize(source)
            @source = source
            @config = nil

            load!
          end

          def loaded?
            @config.present?
          end

          def to_h
            deep_symbolize_keys
          end

          private

          def load!
            @config = YAML.safe_load_file(@source, symbolize_names: true)

          rescue Errno::ENOENT
            Gitlab::Backup::Cli::Output.error "Omnibus configuration file: #{@source} does not exist"
          rescue Errno::EACCES
            Gitlab::Backup::Cli::Output.error "Omnibus configuration file: #{@source} can't be read (permission denied)"
          end
        end
      end
    end
  end
end

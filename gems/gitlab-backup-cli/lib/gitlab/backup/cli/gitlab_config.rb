# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      class GitlabConfig
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

        def initialize(source)
          @source = source
          @config = nil

          load!
        end

        def load!
          yaml = ActiveSupport::ConfigurationFile.parse(@source)
          all_configs = yaml.deep_stringify_keys

          @config = all_configs
        end
      end
    end
  end
end

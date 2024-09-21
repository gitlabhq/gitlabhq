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

        def loaded?
          @config.present?
        end

        private

        def load!
          yaml = ActiveSupport::ConfigurationFile.parse(@source)
          all_configs = yaml.deep_stringify_keys

          @config = all_configs
        rescue Errno::ENOENT
          Gitlab::Backup::Cli::Output.error "GitLab configuration file: #{@source} does not exist"
        rescue Errno::EACCES
          Gitlab::Backup::Cli::Output.error "GitLab configuration file: #{@source} can't be read (permission denied)"
        end
      end
    end
  end
end

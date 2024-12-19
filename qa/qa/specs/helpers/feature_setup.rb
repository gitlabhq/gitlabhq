# frozen_string_literal: true

module QA
  module Specs
    module Helpers
      class FeatureSetup
        class << self
          # Set up feature flags
          #
          # @return [void]
          def configure!
            return if Runtime::Env.dry_run

            configure_rspec
          end

          private

          # Add global hooks to perform feature flag changes
          #
          # @return [void]
          def configure_rspec
            setup = new

            ::RSpec.configure do |config|
              config.before(:suite) { setup.run_before }
              config.after(:suite) { setup.run_after }
            end
          end
        end

        FF_PATTERN = /[a-z_]+=(enabled|disabled)/

        private_class_method :new

        def initialize
          @options = Support::GlobalOptions.get
          @enable_feature = options[:enable_feature]
          @disable_feature = options[:disable_feature]
        end

        # Run feature setup before suite
        #
        # @return [void]
        def run_before
          set_feature_flags

          enable_features
          disable_features
        end

        # Restore feature state after suite
        #
        # @return [void]
        def run_after
          Runtime::Feature.disable(enable_feature) if enable_feature && !enabled
          Runtime::Feature.enable(disable_feature) if disable_feature && !disabled
        end

        private

        delegate :logger, to: Runtime::Logger

        attr_reader :options, :enable_feature, :disable_feature, :enabled, :disabled

        # Feature flags to set
        #
        # @return [<String, nil>]
        def feature_flags
          return @feature_flags if defined?(@feature_flags)

          @feature_flags ||= options[:set_feature_flags] || feature_flags_from_env
        end

        # Fetch feature flags from environment variable
        #
        # @return [<Hash, nil>]
        def feature_flags_from_env
          ff = ENV["QA_FEATURE_FLAGS"]
          return if ff.blank?

          ff.split(",").each_with_object({}) do |flag, hash|
            unless flag.match?(FF_PATTERN)
              error_msg = "'#{flag}' in QA_FEATURE_FLAGS environment variable doesn't match pattern '#{FF_PATTERN}'"
              next logger.error(error_msg)
            end

            name, value = flag.split("=")
            hash[name] = value
          end
        end

        # Update group of feature flags
        #
        # @return [void]
        def set_feature_flags
          return unless feature_flags

          Runtime::Feature.set(feature_flags)
        end

        # Enable features
        #
        # @return [void]
        def enable_features
          return unless enable_feature

          @enabled = Runtime::Feature.enabled?(enable_feature)
          return if @enabled

          Runtime::Feature.enable(enable_feature)
        end

        # Disable features
        #
        # @return [void]
        def disable_features
          return unless disable_feature

          @disabled = !Runtime::Feature.enabled?(disable_feature)
          return if @disabled

          Runtime::Feature.disable(disable_feature)
        end
      end
    end
  end
end

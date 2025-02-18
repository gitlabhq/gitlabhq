# frozen_string_literal: true

module Gitlab
  module Metrics
    module SliConfig
      def self.registered_classes
        @registered_classes ||= {}
      end

      def self.enabled_slis
        SliConfig.registered_classes.filter_map { |_, fn| fn.call }
      end

      def self.register(klass, is_runtime_enabled_block)
        SliConfig.registered_classes[klass.to_s] = -> do
          return unless is_runtime_enabled_block.call

          Gitlab::AppLogger.info "Gitlab::Metrics::SliConfig: enabling #{self}"
          klass
        end
      end

      module ConfigMethods
        def puma_enabled!(enable = true)
          is_runtime_enabled = -> { enable && Gitlab::Runtime.puma? }
          SliConfig.register(self, is_runtime_enabled)
        end

        def sidekiq_enabled!(enable = true)
          is_runtime_enabled = -> { enable && Gitlab::Runtime.sidekiq? }
          SliConfig.register(self, is_runtime_enabled)
        end
      end

      def self.included(base)
        base.extend(ConfigMethods)
      end
    end
  end
end

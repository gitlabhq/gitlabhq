# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      class BaseStrategy
        # Weekly because the ANALYZE targets the parent and so recurses the whole
        # partition hierarchy, a recurring cost on very large tables
        DEFAULT_ANALYZE_INTERVAL = 1.week

        # Strategies that accept a detach_concurrently option set @detach_concurrently in their initializer
        def detach_concurrently?
          @detach_concurrently || false
        end

        # Strategies set @default_analyze_interval when no explicit analyze_interval was given
        def default_analyze_interval?
          @default_analyze_interval || false
        end

        # Strategies that can date a partition's detach eligibility override this
        def detachable_since(_partition)
          nil
        end

        protected

        def ensure_connection_set
          return unless model < SharedModel

          model.ensure_connection_set!
        end
      end
    end
  end
end

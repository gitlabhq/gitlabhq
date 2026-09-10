# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      class BaseStrategy
        # Strategies that accept a detach_concurrently option set @detach_concurrently in their initializer
        def detach_concurrently?
          @detach_concurrently || false
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

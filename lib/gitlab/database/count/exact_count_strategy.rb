# frozen_string_literal: true

module Gitlab
  module Database
    module Count
      # This strategy performs an exact count on the model.
      #
      # This is guaranteed to be accurate, however it also scans the
      # whole table. Hence, there are no guarantees with respect
      # to runtime.
      #
      # Note that for very large tables, this may even timeout.
      class ExactCountStrategy
        attr_reader :models

        def initialize(models)
          @models = models
        end

        def count
          models.index_with(&:count)
        rescue *CONNECTION_ERRORS
          {}
        end
      end
    end
  end
end

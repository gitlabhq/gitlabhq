# frozen_string_literal: true

module Gitlab
  module Database
    module Count
      # A tablesample count executes in two phases:
      # * Estimate table sizes based on reltuples.
      # * Based on the estimate:
      #   * If the table is considered 'small', execute an exact relation count.
      #   * Otherwise, count on a sample of the table using TABLESAMPLE.
      #
      # The size of the sample is chosen in a way that we always roughly scan
      # the same amount of rows (see TABLESAMPLE_ROW_TARGET).
      #
      # There are no guarantees with respect to the accuracy of the result or runtime.
      class TablesampleCountStrategy < ReltuplesCountStrategy
        EXACT_COUNT_THRESHOLD = 10_000
        TABLESAMPLE_ROW_TARGET = 10_000

        def count
          estimates = size_estimates(check_statistics: false)

          models.each_with_object({}) do |model, count_by_model|
            count = perform_count(model, estimates[model])
            count_by_model[model] = count if count
          end
        rescue *CONNECTION_ERRORS
          {}
        end

        private

        def perform_count(model, estimate)
          # If we estimate 0, we may not have statistics at all. Don't use them.
          return unless estimate && estimate > 0

          if estimate < EXACT_COUNT_THRESHOLD
            # The table is considered small, the assumption here is that
            # the exact count will be fast anyways.
            model.count
          else
            # The table is considered large, let's only count on a sample.
            tablesample_count(model, estimate)
          end
        end

        def where_clause(model)
          return unless sti_model?(model)

          "WHERE #{model.inheritance_column} = '#{model.name}'"
        end

        def tablesample_count(model, estimate)
          portion = (TABLESAMPLE_ROW_TARGET.to_f / estimate).round(4)
          inverse = 1 / portion
          query = <<~SQL
            SELECT (COUNT(*)*#{inverse})::integer AS count
            FROM #{model.table_name}
            TABLESAMPLE SYSTEM (#{portion * 100})
            REPEATABLE (0)
            #{where_clause(model)}
          SQL

          rows = ActiveRecord::Base.connection.select_all(query) # rubocop: disable Database/MultipleDatabases

          Integer(rows.first['count'])
        end
      end
    end
  end
end

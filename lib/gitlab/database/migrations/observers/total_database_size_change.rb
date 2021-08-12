# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      module Observers
        class TotalDatabaseSizeChange < MigrationObserver
          def before
            @size_before = get_total_database_size
          end

          def after
            @size_after = get_total_database_size
          end

          def record
            return unless @size_after && @size_before

            observation.total_database_size_change = @size_after - @size_before
          end

          private

          def get_total_database_size
            connection.execute("select pg_database_size(current_database())").first['pg_database_size']
          end
        end
      end
    end
  end
end

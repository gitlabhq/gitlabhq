# frozen_string_literal: true

module Peek
  module Views
    class ActiveRecord < DetailedView
      private

      def setup_subscribers
        super

        subscribe('sql.active_record') do |_, start, finish, _, data|
          if Gitlab::PerformanceBar.enabled_for_request?
            unless data[:cached]
              detail_store << {
                duration: finish - start,
                sql: data[:sql].strip,
                backtrace: Gitlab::Profiler.clean_backtrace(caller)
              }
            end
          end
        end
      end
    end
  end
end

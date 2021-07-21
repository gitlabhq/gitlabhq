# frozen_string_literal: true

module Gitlab
  module Database
    class Metrics
      extend ::Gitlab::Utils::StrongMemoize

      class << self
        def subtransactions_increment(model_name)
          subtransactions_counter.increment(model: model_name)
        end

        private

        def subtransactions_counter
          strong_memoize(:subtransactions_counter) do
            name = :gitlab_active_record_subtransactions_total
            comment = 'Total amount of subtransactions created by ActiveRecord'

            ::Gitlab::Metrics.counter(name, comment)
          end
        end
      end
    end
  end
end

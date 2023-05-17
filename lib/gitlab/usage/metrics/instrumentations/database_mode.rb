# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class DatabaseMode < GenericMetric
          value do
            Gitlab::Database.database_mode
          end
        end
      end
    end
  end
end

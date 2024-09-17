# frozen_string_literal: true

module ClickHouse # rubocop:disable Gitlab/BoundedContexts -- Existing module
  module Models
    module Ci
      class FinishedPipelinesHourly < FinishedPipelinesBase
        def self.table_name
          'ci_finished_pipelines_hourly'
        end
      end
    end
  end
end

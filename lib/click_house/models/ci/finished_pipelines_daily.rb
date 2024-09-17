# frozen_string_literal: true

module ClickHouse # rubocop:disable Gitlab/BoundedContexts -- Existing module
  module Models
    module Ci
      class FinishedPipelinesDaily < FinishedPipelinesBase
        def self.table_name
          'ci_finished_pipelines_daily'
        end
      end
    end
  end
end

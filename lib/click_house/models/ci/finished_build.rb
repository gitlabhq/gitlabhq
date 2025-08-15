# frozen_string_literal: true

module ClickHouse # rubocop:disable Gitlab/BoundedContexts -- Existing module
  module Models
    module Ci
      class FinishedBuild
        class << self
          def table_name
            'ci_finished_builds'
          end
        end
      end
    end
  end
end

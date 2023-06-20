# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountPersonalSnippetsMetric < DatabaseMetric
          operation :count

          relation do
            PersonalSnippet
          end
        end
      end
    end
  end
end

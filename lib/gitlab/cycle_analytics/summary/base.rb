# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module Summary
      class Base
        def initialize(project:, from:, to: nil)
          @project = project
          @from = from
          @to = to
        end

        def title
          raise NotImplementedError.new("Expected #{self.name} to implement title")
        end

        def value
          raise NotImplementedError.new("Expected #{self.name} to implement value")
        end
      end
    end
  end
end

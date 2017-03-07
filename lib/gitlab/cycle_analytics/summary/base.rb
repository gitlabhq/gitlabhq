module Gitlab
  module CycleAnalytics
    module Summary
      class Base
        def initialize(project:, from:)
          @project = project
          @from = from
        end

        def title
          self.class.name.demodulize
        end

        def value
          raise NotImplementedError.new("Expected #{self.name} to implement value")
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module Summary
      module Group
        class Base
          def initialize(group:, from:)
            @group = group
            @from = from
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
end

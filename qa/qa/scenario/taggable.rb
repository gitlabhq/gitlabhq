module QA
  module Scenario
    module Taggable
      def tags(*tags)
        @tags = tags
      end

      def focus
        @tags.to_a
      end
    end
  end
end

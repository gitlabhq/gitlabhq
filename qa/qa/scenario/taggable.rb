module QA
  module Scenario
    module Taggable
      def tags(*tags)
        @tags = tags # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end

      def focus
        @tags.to_a # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end
    end
  end
end

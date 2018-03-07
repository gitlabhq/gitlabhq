module QA
  module Scenario
    module Taggable
      # rubocop:disable Gitlab/ModuleWithInstanceVariables

      def tags(*tags)
        @tags = tags
      end

      def focus
        @tags.to_a
      end

      # rubocop:enable Gitlab/ModuleWithInstanceVariables
    end
  end
end

module QA
  module Page
    module Mattermost
      class Main < Page::Base
        def initialize
          visit(Runtime::Scenario.mattermost)
        end
      end
    end
  end
end

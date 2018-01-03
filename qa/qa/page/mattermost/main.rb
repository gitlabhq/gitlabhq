module QA
  module Page
    module Mattermost
      class Main < Page::Base
        def initialize
          visit(Runtime::Scenario.mattermost_address)
        end
      end
    end
  end
end

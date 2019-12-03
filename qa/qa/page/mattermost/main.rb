# frozen_string_literal: true

module QA
  module Page
    module Mattermost
      class Main < Page::Base
        view 'app/views/projects/mattermosts/new.html.haml'

        def initialize
          visit(Runtime::Scenario.mattermost_address)
        end
      end
    end
  end
end

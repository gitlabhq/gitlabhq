module QA
  module Page
    module Mattermost
      class Main < Page::Base
        ##
        # TODO, define all selectors required by this page object
        #
        # See gitlab-org/gitlab-qa#154
        #
        view 'app/views/projects/mattermosts/new.html.haml'

        def initialize
          visit(Runtime::Scenario.mattermost_address)
        end
      end
    end
  end
end

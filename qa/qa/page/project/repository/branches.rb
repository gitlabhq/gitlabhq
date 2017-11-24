module QA
  module Page
    module Gitlab
      module Project
        module Repository
          class Branches < Page::Base
            # this should return the Branch::New page
            def new
              click_link 'New branch'
            end
          end
        end
      end
    end
  end
end

module QA
  module Page
    module Gitlab
      module Project
        class Menu < Page::Base

          def branches
            click_link 'Branches'
          end

        end
      end
    end
  end
end

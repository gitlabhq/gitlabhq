module QA
  module Page
    module Project
      module Repository
        class Branches < Page::Base
          def new
            click_link 'New branch'
          end
        end
      end
    end
  end
end

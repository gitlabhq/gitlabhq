module QA
  module Page
    module Project
      class Menu < Page::Base
        def branches
          find('a', text: /\ABranch/).click
        end
      end
    end
  end
end

module QA
  module Page
    module Issuable
      class Sidebar < Page::Base
        view 'app/views/shared/issuable/_sidebar.html.haml' do
          element :labels_block, ".issuable-show-labels"
        end

        def has_label?(label)
          page.within('.issuable-show-labels') do
            !!find('span', text: label)
          end
        end
      end
    end
  end
end

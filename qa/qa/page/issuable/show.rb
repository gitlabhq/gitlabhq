module QA
  module Page
    module Issuable
      class Show < Page::Base
        view 'app/views/shared/issuable/_sidebar.html.haml' do
          element :labels_block, ".issuable-show-labels"
        end

        def has_label?(label)
          page.within('.issuable-show-labels') do
            element = find('span', text: label, wait: 1)
            !element.nil?
          end
        end
      end
    end
  end
end

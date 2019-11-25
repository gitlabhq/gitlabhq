# frozen_string_literal: true

module QA
  module Page
    module Issuable
      class Sidebar < Page::Base
        view 'app/views/shared/issuable/_sidebar.html.haml' do
          element :labels_block
          element :milestone_block
          element :milestone_title
        end

        def has_label?(label)
          within_element(:labels_block) do
            has_element?(:label, label_name: label)
          end
        end

        def has_milestone?(milestone)
          within_element(:milestone_block) do
            has_element?(:milestone_title, text: milestone)
          end
        end
      end
    end
  end
end

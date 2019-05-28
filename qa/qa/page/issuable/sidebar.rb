# frozen_string_literal: true

module QA
  module Page
    module Issuable
      class Sidebar < Page::Base
        view 'app/views/shared/issuable/_sidebar.html.haml' do
          element :labels_block, ".issuable-show-labels" # rubocop:disable QA/ElementWithPattern
          element :milestones_block, '.block.milestone' # rubocop:disable QA/ElementWithPattern
        end

        def has_label?(label)
          page.within('.issuable-show-labels') do
            !!find('span', text: label)
          end
        end

        def has_milestone?(milestone)
          page.within('.block.milestone') do
            !!find("[href*='/milestones/']", text: milestone)
          end
        end
      end
    end
  end
end

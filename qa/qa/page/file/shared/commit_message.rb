# frozen_string_literal: true

module QA
  module Page
    module File
      module Shared
        module CommitMessage
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.view 'app/views/shared/_commit_message_container.html.haml' do
              element :commit_message, "text_area_tag 'commit_message'" # rubocop:disable QA/ElementWithPattern
            end
          end

          def add_commit_message(message)
            fill_in 'commit_message', with: message
          end
        end
      end
    end
  end
end

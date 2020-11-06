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

            base.view 'app/views/projects/commits/_commit.html.haml' do
              element :commit_content
            end
          end

          def add_commit_message(message)
            fill_in 'commit_message', with: message
          end

          def has_commit_message?(text)
            has_element?(:commit_content, text: text)
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module QA
  module Page
    module File
      module Shared
        module CommitButton
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.view 'app/views/projects/_commit_button.html.haml' do
              element :commit_button
            end
          end

          def commit_changes
            click_element(:commit_button)

            wait_until(reload: false, max_duration: 60) do
              finished_loading?
            end
          end
        end
      end
    end
  end
end

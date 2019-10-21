# frozen_string_literal: true

module QA
  module Page
    module File
      module Shared
        module CommitButton
          def self.included(base)
            base.view 'app/views/projects/_commit_button.html.haml' do
              element :commit_button
            end
          end

          def commit_changes
            click_element(:commit_button)

            wait(reload: false, max: 60) do
              finished_loading?
            end
          end
        end
      end
    end
  end
end

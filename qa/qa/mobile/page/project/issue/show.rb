# frozen_string_literal: true

module QA
  module Mobile
    module Page
      module Project
        module Issue
          module Show
            extend QA::Page::PageConcern

            def self.prepended(base)
              super

              base.class_eval do
                view 'app/assets/javascripts/issues/show/components/header_actions.vue' do
                  element :issue_actions_dropdown
                  element :mobile_close_issue_button
                  element :mobile_reopen_issue_button
                end
              end
            end

            def click_close_issue_button
              find('[data-qa-selector="issue_actions_dropdown"] > button').click
              find_element(:mobile_close_issue_button, visible: false).click
            end

            def has_reopen_issue_button?
              find('[data-qa-selector="issue_actions_dropdown"] > button').click
              has_element?(:mobile_reopen_issue_button)
            end
          end
        end
      end
    end
  end
end

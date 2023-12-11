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
                  element 'mobile-dropdown'
                  element 'mobile-close-issue-button'
                  element 'mobile-reopen-issue-button'
                end
              end
            end

            def click_close_issue_button
              find('[data-testid="mobile-dropdown"] > button').click
              find_element('mobile-close-issue-button', visible: false).click
            end

            def has_reopen_issue_button?
              find('[data-testid="mobile-dropdown"] > button').click
              has_element?('mobile-reopen-issue-button')
            end
          end
        end
      end
    end
  end
end

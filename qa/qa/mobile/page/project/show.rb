# frozen_string_literal: true

module QA
  module Mobile
    module Page
      module Project
        module Show
          extend QA::Page::PageConcern

          def self.prepended(base)
            super

            base.class_eval do
              prepend QA::Mobile::Page::Main::Menu

              view 'app/assets/javascripts/nav/components/top_nav_new_dropdown.vue' do
                element :new_issue_mobile_button
              end
            end
          end

          def go_to_new_issue
            open_mobile_new_dropdown

            click_element(:new_issue_mobile_button)
          end
        end
      end
    end
  end
end

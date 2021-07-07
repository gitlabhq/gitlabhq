# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module Project
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.class_eval do
              include QA::Page::Project::SubMenus::Common

              view 'app/views/shared/nav/_scope_menu.html.haml' do
                element :project_scope_link
              end
            end
          end

          def click_project
            retry_on_exception do
              within_sidebar do
                click_element(:project_scope_link)
              end
            end
          end
        end
      end
    end
  end
end

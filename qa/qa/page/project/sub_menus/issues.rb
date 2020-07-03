# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module Issues
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.class_eval do
              include QA::Page::Project::SubMenus::Common

              view 'app/views/layouts/nav/sidebar/_project.html.haml' do
                element :issue_boards_link
                element :issues_item
                element :labels_link
                element :milestones_link
              end
            end
          end

          def click_issues
            within_sidebar do
              click_link('Issues')
            end
          end

          def click_milestones
            within_sidebar do
              click_element :milestones_link
            end
          end

          def go_to_boards
            hover_issues do
              within_submenu do
                click_element(:issue_boards_link)
              end
            end
          end

          def go_to_labels
            hover_issues do
              within_submenu do
                click_element(:labels_link)
              end
            end
          end

          def go_to_milestones
            hover_issues do
              within_submenu do
                click_element(:milestones_link)
              end
            end
          end

          private

          def hover_issues
            within_sidebar do
              scroll_to_element(:issues_item)
              find_element(:issues_item).hover

              yield
            end
          end
        end
      end
    end
  end
end

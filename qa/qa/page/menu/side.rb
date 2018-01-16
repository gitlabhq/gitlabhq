module QA
  module Page
    module Menu
      class Side < Page::Base
        view 'app/views/layouts/nav/sidebar/_project.html.haml' do
          element :settings_item
          element :repository_link, "title: 'Repository'"
          element :top_level_items, '.sidebar-top-level-items'
          element :activity_link, "title: 'Activity'"
        end

        def click_repository_setting
          hover_setting do
            click_link('Repository')
          end
        end

        private

        def hover_setting
          within_sidebar do
            find('.qa-settings-item').hover

            yield
          end
        end

        def within_sidebar
          page.within('.sidebar-top-level-items') do
            yield
          end
        end

        def go_to_activity
          click_on class: 'shortcuts-project-activity'
        end
      end
    end
  end
end

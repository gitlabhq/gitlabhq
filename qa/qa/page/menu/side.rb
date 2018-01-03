module QA
  module Page
    module Menu
      class Side < Page::Base
        def click_repository_setting
          hover_setting do
            click_link('Repository')
          end
        end

        private

        def hover_setting
          within_sidebar do
            find('.nav-item-name', text: 'Settings').hover

            yield
          end
        end

        def within_sidebar
          page.within('.sidebar-top-level-items') do
            yield
          end
        end
      end
    end
  end
end

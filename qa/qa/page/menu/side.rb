module QA
  module Page
    module Menu
      class Side < Page::Base
        view 'app/views/layouts/nav/sidebar/_project.html.haml' do
          element :settings_item
          element :repository_link, "title: 'Repository'"
          element :top_level_items, '.sidebar-top-level-items'
        end

        view 'app/assets/javascripts/fly_out_nav.js' do
          element :fly_out, "IS_SHOWING_FLY_OUT_CLASS = 'is-showing-fly-out'"
        end

        def click_repository_setting
          hover_setting do
            click_link('Repository')
          end
        end

        def click_cicd_setting
          hover_setting do
            click_link('CI / CD')
          end
        end

        private

        def hover_setting
          within_sidebar do
            find('.qa-settings-item').hover

            within_fly_out do
              yield
            end
          end
        end

        def within_sidebar
          page.within('.sidebar-top-level-items') do
            yield
          end
        end

        def within_fly_out
          page.within('.is-showing-fly-out') do
            yield
          end
        end
      end
    end
  end
end

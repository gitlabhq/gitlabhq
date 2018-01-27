module QA
  module Page
    module Menu
      class Side < Page::Base
        view 'app/views/layouts/nav/sidebar/_project.html.haml' do
          element :settings_item
          element :settings_link, 'link_to edit_project_path'
          element :repository_link, "title: 'Repository'"
          element :pipelines_settings_link, "title: 'CI / CD'"
          element :issues_link, /link_to.*shortcuts-issues/
          element :issues_link_text, "Issues"
          element :top_level_items, '.sidebar-top-level-items'
          element :activity_link, "title: 'Activity'"
        end

        view 'app/assets/javascripts/fly_out_nav.js' do
          element :fly_out, "classList.add('fly-out-list')"
        end

        def click_repository_settings
          hover_settings do
            within_submenu do
              click_link('Repository')
            end
          end
        end

        def click_ci_cd_settings
          hover_settings do
            within_submenu do
              click_link('CI / CD')
            end
          end
        end

        def click_ci_cd_pipelines
          within_sidebar do
            click_link('CI / CD')
          end
        end

        def go_to_settings
          within_sidebar do
            click_on 'Settings'
          end
        end

        def click_issues
          within_sidebar do
            click_link('Issues')
          end
        end

        private

        def hover_settings
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
          within_sidebar do
            click_on 'Activity'
          end
        end

        def within_submenu
          page.within('.fly-out-list') do
            yield
          end
        end
      end
    end
  end
end

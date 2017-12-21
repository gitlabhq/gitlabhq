module QA
  module Page
    module Project
      class Show < Page::Base
        def choose_repository_clone_http
          find('#clone-dropdown').click

          page.within('.clone-options-dropdown') do
            click_link('HTTP')
          end
        end

        def click_repository_setting
          hover_setting do
            click_link('Repository')
          end
        end

        def repository_location
          find('#project_clone').value
        end

        def project_name
          find('.project-title').text
        end

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

        def wait_for_push
          sleep 5
        end
      end
    end
  end
end

module QA
  module Page
    module Project
      class Show < Page::Base
        view 'app/views/shared/_clone_panel.html.haml' do
          element :clone_dropdown
          element :clone_options_dropdown, '.clone-options-dropdown'
        end

        view 'app/views/shared/_clone_panel.html.haml' do
          element :project_repository_location, 'text_field_tag :project_clone'
        end

        view 'app/views/projects/_home_panel.html.haml' do
          element :project_name
        end

        def choose_repository_clone_http
          click_element :clone_dropdown

          page.within('.clone-options-dropdown') do
            click_link('HTTP')
          end
        end

        def repository_location
          find('#project_clone').value
        end

        def project_name
          find('.qa-project-name').text
        end

        def wait_for_push
          sleep 5
          refresh
        end
      end
    end
  end
end

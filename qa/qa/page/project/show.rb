module QA
  module Page
    module Project
      class Show < Page::Base
        view 'app/views/shared/_clone_panel.html.haml' do
          element :clone_holder, '.git-clone-holder'
          element :clone_dropdown
          element :clone_options_dropdown, '.clone-options-dropdown'
          element :project_repository_location, 'text_field_tag :project_clone'
        end

        view 'app/views/projects/_last_push.html.haml' do
          element :create_merge_request
        end

        view 'app/views/projects/_home_panel.html.haml' do
          element :project_name
        end

        view 'app/views/layouts/header/_new_dropdown.haml' do
          element :new_menu_toggle
          element :new_issue_link, "link_to 'New issue', new_project_issue_path(@project)"
        end

        def choose_repository_clone_http
          wait(reload: false) do
            click_element :clone_dropdown

            page.within('.clone-options-dropdown') do
              click_link('HTTP')
            end

            # Ensure git clone textbox was updated to http URI
            page.has_css?('.git-clone-holder input#project_clone[value*="http"]')
          end
        end

        def repository_location
          find('#project_clone').value
        end

        def project_name
          find('.qa-project-name').text
        end

        def new_merge_request
          click_element :create_merge_request
        end

        def wait_for_push
          sleep 5
          refresh
        end

        def go_to_new_issue
          click_element :new_menu_toggle

          click_link 'New issue'
        end
      end
    end
  end
end

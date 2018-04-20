module QA
  module Page
    module Project
      class Show < Page::Base
        view 'app/views/shared/_clone_panel.html.haml' do
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

        view 'app/views/shared/_ref_switcher.html.haml' do
          element :branches_select
          element :branches_dropdown
        end

        def choose_repository_clone_http
          choose_repository_clone('HTTP', 'http')
        end

        def choose_repository_clone_ssh
          # It's not always beginning with ssh:// so detecting with @
          # would be more reliable because ssh would always contain it.
          # We can't use .git because HTTP also contain that part.
          choose_repository_clone('SSH', '@')
        end

        def repository_location
          find('#project_clone').value
        end

        def repository_location_uri
          Git::Location.new(repository_location)
        end

        def project_name
          find('.qa-project-name').text
        end

        def switch_to_branch(branch_name)
          find_element(:branches_select).click

          within_element(:branches_dropdown) do
            click_on branch_name
          end
        end

        def last_commit_content
          find_element(:commit_content).text
        end

        def new_merge_request
          wait(reload: true) do
            has_css?(element_selector_css(:create_merge_request))
          end

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

        private

        def choose_repository_clone(kind, detect_text)
          wait(reload: false) do
            click_element :clone_dropdown

            page.within('.clone-options-dropdown') do
              click_link(kind)
            end

            # Ensure git clone textbox was updated
            repository_location.include?(detect_text)
          end
        end
      end
    end
  end
end

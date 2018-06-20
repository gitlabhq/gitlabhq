module QA
  module Page
    module Project
      class Show < Page::Base
        include Page::Shared::ClonePanel

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

        def go_to_new_issue
          click_element :new_menu_toggle

          click_link 'New issue'
        end
      end
    end
  end
end

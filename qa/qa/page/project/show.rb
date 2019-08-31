# frozen_string_literal: true

module QA
  module Page
    module Project
      class Show < Page::Base
        include Page::Component::ClonePanel
        include Page::Project::SubMenus::Settings

        view 'app/views/layouts/header/_new_dropdown.haml' do
          element :new_menu_toggle
          element :new_issue_link, "link_to _('New issue'), new_project_issue_path(@project)" # rubocop:disable QA/ElementWithPattern
        end

        view 'app/views/projects/_last_push.html.haml' do
          element :create_merge_request
        end

        view 'app/views/projects/_home_panel.html.haml' do
          element :project_name
        end

        view 'app/views/projects/_files.html.haml' do
          element :tree_holder, '.tree-holder' # rubocop:disable QA/ElementWithPattern
        end

        view 'app/views/projects/buttons/_dropdown.html.haml' do
          element :create_new_dropdown
        end

        view 'app/views/projects/buttons/_fork.html.haml' do
          element :fork_label, "%span= s_('ProjectOverview|Fork')" # rubocop:disable QA/ElementWithPattern
          element :fork_link, "link_to new_project_fork_path(@project)" # rubocop:disable QA/ElementWithPattern
        end

        view 'app/views/projects/empty.html.haml' do
          element :quick_actions
        end

        view 'app/views/projects/tree/_tree_content.html.haml' do
          element :file_tree
        end

        view 'app/views/projects/tree/_tree_header.html.haml' do
          element :add_to_tree
          element :new_file_option
          element :web_ide_button
        end

        view 'app/views/shared/_ref_switcher.html.haml' do
          element :branches_select
          element :branches_dropdown
        end

        view 'app/views/projects/blob/viewers/_loading.html.haml' do
          element :spinner
        end

        def wait_for_viewers_to_load
          wait(reload: false) do
            has_no_element?(:spinner)
          end
        end

        def create_first_new_file!
          within_element(:quick_actions) do
            click_link_with_text 'New file'
          end
        end

        def create_new_file!
          click_element :add_to_tree
          click_element :new_file_option
        end

        def fork_project
          click_on 'Fork'
        end

        def click_file(filename)
          within_element(:file_tree) do
            click_on filename
          end
        end

        def click_commit(commit_msg)
          within_element(:file_tree) do
            click_on commit_msg
          end
        end

        def go_to_new_issue
          click_element :new_menu_toggle
          click_link 'New issue'
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

        def open_web_ide!
          click_element :web_ide_button
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

        def wait_for_import
          wait(reload: true) do
            has_css?('.tree-holder')
          end
        end
      end
    end
  end
end

QA::Page::Project::Show.prepend_if_ee('QA::EE::Page::Project::Show')

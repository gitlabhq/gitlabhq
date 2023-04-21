# frozen_string_literal: true

module QA
  module Page
    module Project
      class Show < Page::Base
        include Layout::Flash
        include Page::Component::ClonePanel
        include Page::Component::Breadcrumbs
        include Page::File::Shared::CommitMessage
        include Page::Component::Dropdown
        # We need to check phone_layout? instead of mobile_layout? here
        # since tablets have the regular top navigation bar
        prepend Mobile::Page::Project::Show if Runtime::Env.phone_layout?

        view 'app/assets/javascripts/repository/components/preview/index.vue' do
          element :blob_viewer_content
        end

        view 'app/assets/javascripts/repository/components/table/row.vue' do
          element :file_name_link
        end

        view 'app/assets/javascripts/repository/components/table/index.vue' do
          element :file_tree_table
        end

        view 'app/views/layouts/header/_new_dropdown.html.haml' do
          element :new_menu_toggle
        end

        view 'app/views/projects/_last_push.html.haml' do
          element :create_merge_request_button
        end

        view 'app/views/projects/_home_panel.html.haml' do
          element :project_name_content
          element :project_id_content
          element :project_badges_content
          element :badge_image_link
        end

        view 'app/views/projects/_files.html.haml' do
          element :project_buttons
          element :tree_holder, '.tree-holder' # rubocop:disable QA/ElementWithPattern
        end

        view 'app/assets/javascripts/repository/components/fork_info.vue' do
          element :forked_from_link
        end

        view 'app/views/projects/buttons/_fork.html.haml' do
          element :fork_button
        end

        view 'app/views/projects/empty.html.haml' do
          element :quick_actions_container
        end

        view 'app/assets/javascripts/repository/components/breadcrumbs.vue' do
          element :add_to_tree_dropdown
          element :new_file_menu_item
        end

        view 'app/assets/javascripts/vue_shared/components/web_ide_link.vue' do
          element :web_ide_button
        end

        view 'app/views/projects/blob/viewers/_loading.html.haml' do
          element :spinner_placeholder
        end

        view 'app/views/projects/buttons/_download.html.haml' do
          element :download_source_code_button
        end

        view 'app/views/projects/tree/_tree_header.html.haml' do
          element :ref_dropdown_container
        end

        def wait_for_viewers_to_load
          has_no_element?(:spinner_placeholder, wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)
        end

        def create_first_new_file!
          within_element(:quick_actions_container) do
            click_link_with_text 'New file'
          end
        end

        def create_new_file!
          click_element :add_to_tree_dropdown
          click_element :new_file_menu_item
        end

        # Click by JS is needed to bypass the VSCode Web IDE popover
        # Change back to regular click_element when vscode_web_ide FF is removed
        # Rollout issue: https://gitlab.com/gitlab-org/gitlab/-/issues/371084
        def fork_project
          fork_button = find_element(:fork_button)
          click_by_javascript(fork_button)
        end

        def forked_from?(parent_project_name)
          has_element?(:forked_from_link, text: parent_project_name)
        end

        def click_file(filename)
          within_element(:file_tree_table) do
            click_element(:file_name_link, text: filename)
          end
        end

        def click_commit(commit_msg)
          wait_for_requests

          within_element(:file_tree_table) do
            click_on commit_msg
          end
        end

        def has_create_merge_request_button?
          has_css?(element_selector_css(:create_merge_request_button))
        end

        def has_file?(name)
          return false unless has_element?(:file_tree_table)

          within_element(:file_tree_table) do
            has_element?(:file_name_link, text: name)
          end
        end

        def has_no_file?(name)
          within_element(:file_tree_table) do
            has_no_element?(:file_name_link, text: name)
          end
        end

        def has_name?(name)
          has_element?(:project_name_content, text: name)
        end

        def has_readme_content?(text)
          has_element?(:blob_viewer_content, text: text)
        end

        def new_merge_request
          wait_until(reload: true) do
            has_create_merge_request_button?
          end

          click_element :create_merge_request_button
        end

        def open_web_ide!
          click_element(:web_ide_button)
          page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)
        end

        def open_web_ide_via_shortcut
          page.driver.send_keys('.')
          page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)
        end

        def has_edit_fork_button?
          has_element?(:web_ide_button, text: 'Edit fork in Web IDE')
        end

        def project_name
          find_element(:project_name_content).text
        end

        def project_id
          find_element(:project_id_content).text.delete('Project ID: ')
        end

        def switch_to_branch(branch_name)
          within_element(:ref_dropdown_container) do
            expand_select_list
            select_item(branch_name)
          end
        end

        def wait_for_import
          wait_until(reload: true) do
            has_css?('.tree-holder')
          end
        end

        def has_visible_badge_image_link?(link_url)
          within_element(:project_badges_content) do
            has_element?(:badge_image_link, link_url: link_url)
          end
        end

        def has_license?(name)
          within_element(:project_buttons) do
            has_link?(name)
          end
        end
      end
    end
  end
end

QA::Page::Project::Show.prepend_mod_with('Page::Project::Show', namespace: QA)

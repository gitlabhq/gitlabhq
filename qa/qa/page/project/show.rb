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

        view 'app/assets/javascripts/repository/components/preview/index.vue' do
          element 'blob-viewer-content'
        end

        view 'app/assets/javascripts/repository/components/table/row.vue' do
          element 'file-name-link'
        end

        view 'app/assets/javascripts/repository/components/table/index.vue' do
          element 'file-tree-table'
        end

        view 'app/views/projects/_last_push.html.haml' do
          element 'create-merge-request-button'
        end

        view 'app/views/projects/_home_panel.html.haml' do
          element 'project-name-content'
        end

        view 'app/views/projects/_sidebar.html.haml' do
          element 'project-badges-content'
          element 'badge-image-link'
          element 'project-buttons'
        end

        view 'app/assets/javascripts/repository/components/fork_info.vue' do
          element 'forked-from-link'
        end

        view 'app/assets/javascripts/forks/components/forks_button.vue' do
          element 'fork-button'
        end

        view 'app/views/projects/empty.html.haml' do
          element 'quick-actions-container'
        end

        view 'app/assets/javascripts/repository/components/header_area/breadcrumbs.vue' do
          element 'add-to-tree'
          element 'new-file-menu-item'
        end

        view 'app/views/projects/blob/viewers/_loading.html.haml' do
          element 'spinner-placeholder'
        end

        view 'app/assets/javascripts/repository/components/header_area.vue' do
          element 'ref-dropdown-container'
        end

        def wait_for_viewers_to_load
          has_no_element?('spinner-placeholder', wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)
        end

        def create_first_new_file!
          within_element('quick-actions-container') do
            click_link_with_text 'New file'
          end
        end

        def create_new_file!
          click_element 'add-to-tree'
          click_element 'new-file-menu-item'
        end

        # Click by JS is needed to bypass the VSCode Web IDE popover
        # Change back to regular click_element when vscode_web_ide FF is removed
        # Rollout issue: https://gitlab.com/gitlab-org/gitlab/-/issues/371084
        def fork_project
          fork_button = find_element('fork-button')
          click_by_javascript(fork_button)
        end

        def forked_from?(parent_project_name)
          has_element?('forked-from-link', text: parent_project_name)
        end

        def click_file(filename)
          within_element('file-tree-table') do
            click_element('file-name-link', text: filename)
          end
        end

        def click_commit(commit_msg)
          wait_for_requests

          within_element('file-tree-table') do
            click_on commit_msg
          end
        end

        def has_create_merge_request_button?
          has_css?(element_selector_css('create-merge-request-button'))
        end

        def has_file?(name)
          return false unless has_element?('file-tree-table')

          within_element('file-tree-table') do
            has_element?('file-name-link', text: name)
          end
        end

        def has_no_file?(name)
          within_element('file-tree-table') do
            has_no_element?('file-name-link', text: name)
          end
        end

        def has_name?(name)
          has_element?('project-name-content', text: name)
        end

        def has_readme_content?(text)
          has_element?('blob-viewer-content', text: text)
        end

        def new_merge_request
          wait_until(reload: true, message: 'Wait for `Create merge request` push notification') do
            has_create_merge_request_button?
          end

          click_element 'create-merge-request-button'
        end

        def open_web_ide!
          click_element('action-dropdown')
          click_element('webide-menu-item')
          page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)
        end

        def open_web_ide_via_shortcut
          page.driver.send_keys('.')
          page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)
        end

        def has_edit_fork_button?
          click_element('action-dropdown')
          has_element?('webide-menu-item', text: 'Edit fork in Web IDE')
        end

        def project_name
          find_element('project-name-content').text
        end

        def project_id
          find_element('project-id-content').text.delete('Project ID: ')
        end

        def switch_to_branch(branch_name)
          within_element('ref-dropdown-container') do
            expand_select_list
            select_item(branch_name)
          end
        end

        def has_visible_badge_image_link?(link_url)
          within_element('project-badges-content') do
            has_element?('badge-image-link', link_url: link_url)
          end
        end

        def has_license?(name)
          within_element('project-buttons') do
            has_link?(name)
          end
        end
      end
    end
  end
end

QA::Page::Project::Show.prepend_mod_with('Page::Project::Show', namespace: QA)

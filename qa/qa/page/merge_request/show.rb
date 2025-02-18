# frozen_string_literal: true

module QA
  module Page
    module MergeRequest
      class Show < Page::Base
        include Page::Component::Note
        include Page::Component::Issuable::Sidebar

        view 'app/assets/javascripts/batch_comments/components/preview_dropdown.vue' do
          element 'review-preview-dropdown'
        end

        view 'app/assets/javascripts/batch_comments/components/review_bar.vue' do
          element 'review-bar-content'
        end

        view 'app/assets/javascripts/batch_comments/components/submit_dropdown.vue' do
          element 'submit-review-dropdown'
          element 'submit-review-button'
        end

        view 'app/assets/javascripts/diffs/components/compare_dropdown_layout.vue' do
          element 'version-dropdown-content'
        end

        view 'app/assets/javascripts/diffs/components/compare_versions.vue' do
          element 'target-version-dropdown'
          element 'file-tree-button'
        end

        view 'app/assets/javascripts/diffs/components/tree_list.vue' do
          element 'file-tree-container'
          element 'diff-tree-search'
        end

        view 'app/assets/javascripts/diffs/components/diff_file_header.vue' do
          element 'file-title-container'
          element 'options-dropdown-button'
          element 'edit-in-ide-button'
        end

        view 'app/assets/javascripts/vue_shared/components/file_row.vue' do
          element 'file-row-name-container'
        end

        view 'app/assets/javascripts/diffs/components/diff_row.vue' do
          element 'left-comment-button'
          element 'left-line-number'
        end

        view 'app/assets/javascripts/notes/components/note_form.vue' do
          element 'start-review-button'
          element 'comment-now-button'
        end

        view 'app/views/projects/merge_requests/_code_dropdown.html.haml' do
          element 'mr-code-dropdown'
          element 'download-email-patches-menu-item'
          element 'download-plain-diff-menu-item'
          element 'open-in-web-ide-button'
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/mr_widget_pipeline.vue' do
          element 'pipeline-info-container'
          element 'pipeline-id'
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/states/mr_widget_merged.vue' do
          element 'cherry-pick-button'
          element 'revert-button'
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/checks/rebase.vue' do
          element 'standard-rebase-button'
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/states/ready_to_merge.vue' do
          element 'merge-button'
          element 'merge-immediately-dropdown'
          element 'merge-immediately-button'
          element 'merged-status-content'
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/states/sha_mismatch.vue' do
          element 'head-mismatch-content'
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/states/squash_before_merge.vue' do
          element 'squash-checkbox'
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/states/ready_to_merge.vue' do
          element 'widget_edit_commit_message'
        end

        view 'app/assets/javascripts/vue_merge_request_widget/mr_widget_options.vue' do
          element 'mr-widget-content'
          element 'pipeline-container'
        end

        view 'app/assets/javascripts/ci/pipelines_page/components/pipelines_artifacts.vue' do
          element 'artifacts-dropdown'
        end

        view 'app/assets/javascripts/content_editor/components/formatting_toolbar.vue' do
          element 'code-suggestion'
        end

        view 'app/assets/javascripts/vue_shared/components/markdown/apply_suggestion.vue' do
          element 'apply-suggestion-dropdown'
          element 'commit-message-field'
          element 'commit-with-custom-message-button'
        end

        view 'app/assets/javascripts/vue_shared/components/markdown/header.vue' do
          element 'suggestion-button'
          element 'dismiss-suggestion-popover-button'
        end

        view 'app/assets/javascripts/vue_shared/components/markdown/suggestion_diff_header.vue' do
          element 'add-suggestion-batch-button'
          element 'applied-badge'
          element 'applying-badge'
        end

        view 'app/views/projects/merge_requests/_description.html.haml' do
          element 'description-content'
        end

        view 'app/views/projects/merge_requests/_mr_title.html.haml' do
          element 'edit-title-button'
          element 'title-content', required: true
        end

        view 'app/views/projects/merge_requests/_page.html.haml' do
          element 'notes-tab', required: true
          element 'commits-tab', required: true
          element 'diffs-tab', required: true
        end

        view 'app/views/shared/_broadcast_message.html.haml' do
          element 'broadcast-notification-container'
          element 'close-button'
        end

        view 'app/assets/javascripts/ci/jobs_page/components/job_cells/job_cell.vue' do
          element 'fork-icon'
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/mr_collapsible_extension.vue' do
          element 'mr-collapsible-title'
        end

        view 'app/helpers/projects_helper.rb' do
          element 'author-link'
        end

        def start_review
          has_active_element?('start-review-button', wait: 0.5)
          click_element('start-review-button')

          # After clicking the button, wait for it to disappear
          # before moving on to the next part of the test
          has_no_element?('start-review-button')
        end

        def click_target_version_dropdown
          click_element('target-version-dropdown')
        end

        def version_dropdown_content
          find_element('version-dropdown-content').text
        end

        def submit_pending_reviews
          # On test environments we have a broadcast message that can cover the buttons

          if has_element?('broadcast-notification-container', wait: 5)
            within_element('broadcast-notification-container') do
              click_element('close-button')
            end
          end

          within_element('review-bar-content') do
            click_element('review-preview-dropdown')
          end

          click_element('submit-review-dropdown')
          click_element('submit-review-button')

          # After clicking the button, wait for the review bar to disappear
          # before moving on to the next part of the test
          wait_until(reload: false) do
            has_no_element?('review-bar-content')
          end
        end

        def add_comment_to_diff(text)
          wait_until(sleep_interval: 5) do
            has_css?('a[data-linenumber="1"]')
          end

          all_elements('left-line-number', minimum: 1).first.hover
          click_element('left-comment-button')

          click_element('dismiss-suggestion-popover-button') if has_element?('dismiss-suggestion-popover-button',
            wait: 1)

          fill_editor_element('reply-field', text)
        end

        def click_discussions_tab
          click_element('notes-tab')

          wait_for_requests
        end

        def click_commits_tab
          click_element('commits-tab')
        end

        def click_diffs_tab
          click_element('diffs-tab')
        end

        def has_reports_tab?
          has_css?('.reports-tab')
        end

        def click_pipeline_link
          click_element('pipeline-id')
        end

        def edit!
          # Click by JS is needed to bypass the Moved MR actions popover
          # Change back to regular click_element when moved_mr_sidebar FF is removed
          # Rollout issue: https://gitlab.com/gitlab-org/gitlab/-/issues/385460
          click_by_javascript(find_element('edit-title-button', skip_finished_loading_check: true))
        end

        def expand_merge_checks
          within_element('.mr-widget-section') do
            click_element('chevron-lg-down-icon')
          end
        end

        def has_file?(file_name)
          open_file_tree

          return true if has_element?('file-row-name-container', file_name: file_name)

          # Since the file tree uses virtual scrolling, search for file in case it is outside of viewport
          search_file_tree(file_name)
          has_element?('file-row-name-container', file_name: file_name)
        end

        def has_no_file?(file_name)
          # Since the file tree uses virtual scrolling, search for file to ensure non-existence
          search_file_tree(file_name)
          has_no_element?('file-row-name-container', file_name: file_name)
        end

        def search_file_tree(file_name)
          open_file_tree
          fill_element('diff-tree-search', file_name)
        end

        def open_file_tree
          click_element('file-tree-button') if has_no_element?('file-tree-container', wait: 1)
        end

        def has_merge_button?
          has_element?('merge-button', wait: 30)
        end

        def has_no_merge_button?
          has_no_element?('merge-button')
        end

        RSpec::Matchers.define :have_merge_button do
          match(&:has_merge_button?)
          match_when_negated(&:has_no_merge_button?)
        end

        def has_pipeline_status?(text)
          # Pipelines can be slow, so we wait a bit longer than the usual 10 seconds
          wait_until(max_duration: 120, sleep_interval: 5, reload: true) do
            has_element?('pipeline-info-container', text: text, wait: 15)
          end
        end

        def has_title?(title)
          has_element?('title-content', text: title)
        end

        def has_author?(author_username)
          within_element('author-link') do
            has_text?(author_username)
          end
        end

        def has_description?(description)
          has_element?('description-content', text: description)
        end

        def mark_to_squash
          # Refresh page if commit arrived after loading the MR page
          wait_until(reload: true, message: 'Wait for MR to be unblocked') do
            has_no_element?('head-mismatch-content', wait: 1)
          end

          # The squash checkbox is enabled via JS
          wait_until(reload: false) do
            !find_element('squash-checkbox', visible: false).disabled?
          end

          check_element('squash-checkbox', true)
        end

        def edit_commit_message
          check_element('widget_edit_commit_message', true)
        end

        def merge!
          try_to_merge!
          finished_loading?

          raise "Merge did not appear to be successful" unless merged?
        end

        def set_to_auto_merge!
          wait_until_ready_to_merge

          click_element('merge-button', text: 'Set to auto-merge')
        end

        def auto_mergeable?
          has_element?('merge-button', text: 'Set to auto-merge', wait: 10)
        end

        def merged?
          # Reloads the page at this point to avoid the problem of the merge status failing to update
          # That's the transient UX issue this test is checking for, so if the MR is merged but the UI still shows the
          # status as unmerged, the test will fail.
          # Revisit after merge page re-architect is done https://gitlab.com/groups/gitlab-org/-/epics/5598
          # To remove page refresh logic if possible
          # We don't raise on failure because this method is used as a predicate matcher
          retry_until(max_attempts: 3, reload: true, raise_on_failure: false) do
            has_element?('merged-status-content', text: /The changes were merged into|Changes merged into/, wait: 20)
          end
        end

        RSpec::Matchers.define :be_mergeable do
          match do |page|
            page.has_element?('merge-button', disabled: false)
          end

          match_when_negated do |page|
            has_css?('.mr-widget-section', text: 'Merge blocked') || # Merge widget indicates merge is blocked
              page.has_no_element?('merge-button') ||                # No merge button
              page.find_element('merge-button').disabled? == true    # There is a merge button, but it is disabled
          end
        end

        # Waits up 10 seconds and returns false if the Revert button is not enabled
        def revertible?
          has_element?('revert-button', disabled: false, wait: 10)
        end

        # Waits up 60 seconds and raises an error if unable to merge.
        #
        # If a state is encountered in which a user would typically refresh the page, this will refresh the page and
        # then check again if it's ready to merge. For example, it will refresh if a new change was pushed and the page
        # needs to be refreshed to show the change.
        #
        def wait_until_ready_to_merge
          wait_until(message: "Waiting for ready to merge", sleep_interval: 1) do
            # changes in mr are rendered async, because of that mr can sometimes show no changes and there will be no
            # merge button, in such case we must retry loop otherwise find_element will raise ElementNotFound error
            next false unless has_element?('merge-button', wait: 1)

            break true unless find_element('merge-button').disabled?

            # If the widget shows "Merge blocked: new changes were just added" we can refresh the page and check again
            next false if has_element?('head-mismatch-content', wait: 1)

            QA::Runtime::Logger.debug("MR widget text: \"#{mr_widget_text}\"")

            false
          end
        end

        def rebase!
          # The rebase button is disabled on load
          wait_until do
            has_element?('standard-rebase-button')
          end

          # The rebase button is enabled via JS
          wait_until(reload: false) do
            !find_element('standard-rebase-button').disabled?
          end

          click_element('standard-rebase-button')
        end

        def merge_immediately!
          retry_until(reload: true, sleep_interval: 1, max_attempts: 12) do
            if has_element?('merge-immediately-dropdown')
              click_element('merge-immediately-dropdown', skip_finished_loading_check: true)
              click_element('merge-immediately-button', skip_finished_loading_check: true)
            else
              click_element('merge-button', skip_finished_loading_check: true)
            end

            merged?
          end
        end

        def try_to_merge!(wait_for_no_auto_merge: true)
          wait_until_ready_to_merge
          wait_until { !find_element('merge-button').text.include?('auto-merge') } if wait_for_no_auto_merge # rubocop:disable Rails/NegateInclude -- Wait for text auto-merge to change

          click_element('merge-button')
        end

        def view_email_patches
          # Click by JS is needed to bypass the Moved MR actions popover
          # Change back to regular click_element when moved_mr_sidebar FF is removed
          # Rollout issue: https://gitlab.com/gitlab-org/gitlab/-/issues/385460
          click_by_javascript(find_element('mr-code-dropdown'))
          visit_link_in_element('download-email-patches-menu-item')
        end

        def view_plain_diff
          # Click by JS is needed to bypass the Moved MR actions popover
          # Change back to regular click_element when moved_mr_sidebar FF is removed
          # Rollout issue: https://gitlab.com/gitlab-org/gitlab/-/issues/385460
          click_by_javascript(find_element('mr-code-dropdown'))
          visit_link_in_element('download-plain-diff-menu-item')
        end

        def click_open_in_web_ide
          # Click by JS is needed to bypass the Moved MR actions popover
          # Change back to regular click_element when moved_mr_sidebar FF is removed
          # Rollout issue: https://gitlab.com/gitlab-org/gitlab/-/issues/385460
          click_by_javascript(find_element('mr-code-dropdown'))
          click_element('open-in-web-ide-button')
          page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)
          wait_for_requests
        end

        def edit_file_in_web_ide(file_name)
          within_element('file-title-container', file_name: file_name) do
            click_element('options-dropdown-button')
            click_element('edit-in-ide-button')
          end
          page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)
        end

        def add_suggestion_to_diff(suggestion, line)
          find("a[data-linenumber='#{line}']").hover
          click_element('left-comment-button')

          if has_element?('suggestion-button', wait: 0.5)
            click_element('suggestion-button')
            initial_content = find_element('reply-field').value
            fill_editor_element('reply-field', '')
            fill_editor_element('reply-field',
              initial_content.gsub(/(```suggestion:-0\+0\n).*(\n```)/, "\\1#{suggestion}\\2"))
          else
            click_element('code-suggestion')
            suggestion_field = find_element('suggestion-field')
            suggestion_field.set(suggestion)
            has_active_element?('comment-now-button', wait: 0.5)
          end

          click_element('comment-now-button')
          wait_for_requests
        end

        def apply_suggestion_with_message(message)
          all_elements('apply-suggestion-dropdown', minimum: 1).first.click
          fill_element('commit-message-field', message)
          click_element('commit-with-custom-message-button')
        end

        def add_suggestion_to_batch
          all_elements('add-suggestion-batch-button', minimum: 1).first.click
        end

        def has_suggestions_applied?(count = 1)
          wait_until(reload: false) do
            has_no_element?('applying-badge')
          end
          all_elements('applied-badge', count: count)
        end

        def cherry_pick!
          click_element('cherry-pick-button', Page::Component::CommitModal)
          click_element('submit-commit')
        end

        def revert_change!
          # reload page when the revert modal occasionally doesn't appear in ee:large-setup job
          # https://gitlab.com/gitlab-org/gitlab/-/issues/386623 (transient issue)
          retry_on_exception(reload: true) do
            click_element('revert-button', Page::Component::CommitModal)
          end
          click_element('submit-commit')
        end

        def mr_widget_text
          find_element('mr-widget-content').text
        rescue Capybara::ElementNotFound
          ""
        end

        def has_fork_icon?
          has_element?('fork-icon', skip_finished_loading_check: true)
        end

        def click_artifacts_dropdown_button
          wait_for_requests
          within_element('artifacts-dropdown') do
            click_element('base-dropdown-toggle')
          end
        end

        def has_artifact_with_name?(name)
          has_text?(name)
        end

        def has_artifacts_dropdown?
          has_element?('artifacts-dropdown')
        end

        def has_no_artifacts_dropdown?
          has_no_element?('artifacts-dropdown')
        end

        def open_exposed_artifacts_list
          within_element('pipeline-container') do
            wait_until(reload: false) { has_no_text?('Loading artifacts') }
            click_element('mr-collapsible-title')
          end
        end

        def has_exposed_artifact_with_name?(name)
          has_link?(name)
        end
      end
    end
  end
end

QA::Page::MergeRequest::Show.prepend_mod_with('Page::MergeRequest::Show', namespace: QA)

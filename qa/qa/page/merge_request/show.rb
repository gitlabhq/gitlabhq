# frozen_string_literal: true

module QA
  module Page
    module MergeRequest
      class Show < Page::Base
        include Page::Component::Note
        include Page::Component::Issuable::Sidebar

        view 'app/assets/javascripts/batch_comments/components/preview_dropdown.vue' do
          element :review_preview_dropdown
        end

        view 'app/assets/javascripts/batch_comments/components/review_bar.vue' do
          element :review_bar_content
        end

        view 'app/assets/javascripts/batch_comments/components/submit_dropdown.vue' do
          element :submit_review_dropdown
          element :submit_review_button
        end

        view 'app/assets/javascripts/diffs/components/compare_dropdown_layout.vue' do
          element :dropdown_content
        end

        view 'app/assets/javascripts/diffs/components/compare_versions.vue' do
          element :target_version_dropdown
          element :file_tree_button
        end

        view 'app/assets/javascripts/diffs/components/tree_list.vue' do
          element :file_tree_container
          element :diff_tree_search
        end

        view 'app/assets/javascripts/diffs/components/diff_file_header.vue' do
          element :file_name_content
          element :file_title_container
          element :dropdown_button
          element :edit_in_ide_button
        end

        view 'app/assets/javascripts/diffs/components/diff_row.vue' do
          element :diff_comment_button
          element :new_diff_line_link
        end

        view 'app/assets/javascripts/notes/components/note_form.vue' do
          element :start_review_button
          element :comment_now_button
        end

        view 'app/views/projects/merge_requests/_code_dropdown.html.haml' do
          element :mr_code_dropdown
          element :download_email_patches_menu_item
          element :download_plain_diff_menu_item
          element :open_in_web_ide_button
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/mr_widget_pipeline.vue' do
          element :merge_request_pipeline_info_content
          element :pipeline_link
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/states/mr_widget_failed_to_merge.vue' do
          element :merge_request_error_content
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/states/mr_widget_merged.vue' do
          element :cherry_pick_button
          element :revert_button
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/states/mr_widget_rebase.vue' do
          element :mr_rebase_button
          element :no_fast_forward_message_content
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/states/ready_to_merge.vue' do
          element :merge_button
          element :merge_moment_dropdown
          element :merge_immediately_menu_item
          element :merged_status_content
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/states/sha_mismatch.vue' do
          element :head_mismatch_content
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/states/squash_before_merge.vue' do
          element :squash_checkbox
        end

        view 'app/assets/javascripts/vue_merge_request_widget/mr_widget_options.vue' do
          element :mr_widget_content
        end

        view 'app/assets/javascripts/vue_shared/components/markdown/apply_suggestion.vue' do
          element :apply_suggestion_dropdown
          element :commit_message_field
          element :commit_with_custom_message_button
        end

        view 'app/assets/javascripts/vue_shared/components/markdown/header.vue' do
          element :suggestion_button
          element :dismiss_suggestion_popover_button
        end

        view 'app/assets/javascripts/vue_shared/components/markdown/suggestion_diff_header.vue' do
          element :add_suggestion_batch_button
          element :applied_badge
          element :applying_badge
        end

        view 'app/views/projects/merge_requests/_description.html.haml' do
          element :description_content
        end

        view 'app/views/projects/merge_requests/_mr_title.html.haml' do
          element :edit_button
          element :title_content, required: true
        end

        view 'app/views/projects/merge_requests/_page.html.haml' do
          element :notes_tab, required: true
          element :commits_tab, required: true
          element :diffs_tab, required: true
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/states/mr_widget_auto_merge_enabled.vue' do
          element :cancel_auto_merge_button
        end

        view 'app/views/shared/_broadcast_message.html.haml' do
          element :broadcast_notification_container
          element :close_button
        end

        def start_review
          click_element(:start_review_button)

          # After clicking the button, wait for it to disappear
          # before moving on to the next part of the test
          has_no_element?(:start_review_button)
        end

        def click_target_version_dropdown
          click_element(:target_version_dropdown)
        end

        def version_dropdown_content
          find_element(:dropdown_content).text
        end

        def submit_pending_reviews
          # On test environments we have a broadcast message that can cover the buttons

          if has_element?(:broadcast_notification_container, wait: 5)
            within_element(:broadcast_notification_container) do
              click_element(:close_button)
            end
          end

          within_element(:review_bar_content) do
            click_element(:review_preview_dropdown)
          end

          click_element(:submit_review_dropdown)
          click_element(:submit_review_button)

          # After clicking the button, wait for the review bar to disappear
          # before moving on to the next part of the test
          wait_until(reload: false) do
            has_no_element?(:review_bar_content)
          end
        end

        def add_comment_to_diff(text)
          wait_until(sleep_interval: 5) do
            has_css?('a[data-linenumber="1"]')
          end

          all_elements(:new_diff_line_link, minimum: 1).first.hover
          click_element(:diff_comment_button)
          click_element(:dismiss_suggestion_popover_button) if has_element?(:dismiss_suggestion_popover_button, wait: 1)

          fill_element(:reply_field, text)
        end

        def click_discussions_tab
          click_element(:notes_tab)

          wait_for_requests
        end

        def click_commits_tab
          click_element(:commits_tab)
        end

        def click_diffs_tab
          # Do not wait for spinner due to https://gitlab.com/gitlab-org/gitlab/-/issues/398584
          click_element(:diffs_tab, skip_finished_loading_check: true)

          # If the diff isn't available when we navigate to the Changes tab
          # we must reload the page. https://gitlab.com/gitlab-org/gitlab/-/issues/398557
          wait_until(reload: true, skip_finished_loading_check_on_refresh: true) do
            QA::Runtime::Logger.debug('Ensuring that diff has loaded async')
            has_element?(:file_tree_button, skip_finished_loading_check: true, wait: 5)
          end
        end

        def click_pipeline_link
          click_element(:pipeline_link)
        end

        def edit!
          # Click by JS is needed to bypass the Moved MR actions popover
          # Change back to regular click_element when moved_mr_sidebar FF is removed
          # Rollout issue: https://gitlab.com/gitlab-org/gitlab/-/issues/385460
          click_by_javascript(find_element(:edit_button))
        end

        def fast_forward_not_possible?
          has_element?(:no_fast_forward_message_content)
        end

        def has_file?(file_name)
          open_file_tree

          return true if has_element?(:file_name_content, file_name: file_name)

          # Since the file tree uses virtual scrolling, search for file in case it is outside of viewport
          search_file_tree(file_name)
          has_element?(:file_name_content, file_name: file_name)
        end

        def has_no_file?(file_name)
          # Since the file tree uses virtual scrolling, search for file to ensure non-existence
          search_file_tree(file_name)
          has_no_element?(:file_name_content, file_name: file_name)
        end

        def search_file_tree(file_name)
          open_file_tree
          fill_element(:diff_tree_search, file_name)
        end

        def open_file_tree
          click_element(:file_tree_button) unless has_element?(:file_tree_container)
        end

        def has_merge_button?
          refresh

          has_element?(:merge_button)
        end

        def has_no_merge_button?
          refresh

          has_no_element?(:merge_button)
        end

        RSpec::Matchers.define :have_merge_button do
          match(&:has_merge_button?)
          match_when_negated(&:has_no_merge_button?)
        end

        def has_pipeline_status?(text)
          # Pipelines can be slow, so we wait a bit longer than the usual 10 seconds
          wait_until(max_duration: 120, sleep_interval: 5, reload: true) do
            has_element?(:merge_request_pipeline_info_content, text: text, wait: 15)
          end
        end

        def has_title?(title)
          has_element?(:title_content, text: title)
        end

        def has_description?(description)
          has_element?(:description_content, text: description)
        end

        def mark_to_squash
          # The squash checkbox is enabled via JS
          wait_until(reload: false) do
            !find_element(:squash_checkbox, visible: false).disabled?
          end

          check_element(:squash_checkbox, true)
        end

        def merge!
          try_to_merge!
          finished_loading?

          raise "Merge did not appear to be successful" unless merged?
        end

        def merge_when_pipeline_succeeds!
          wait_until_ready_to_merge

          click_element(:merge_button, text: 'Merge when pipeline succeeds')
        end

        def merged?
          # Reloads the page at this point to avoid the problem of the merge status failing to update
          # That's the transient UX issue this test is checking for, so if the MR is merged but the UI still shows the
          # status as unmerged, the test will fail.
          # Revisit after merge page re-architect is done https://gitlab.com/groups/gitlab-org/-/epics/5598
          # To remove page refresh logic if possible
          # We don't raise on failure because this method is used as a predicate matcher
          retry_until(max_attempts: 3, reload: true, raise_on_failure: false) do
            has_element?(:merged_status_content, text: /The changes were merged into|Changes merged into/, wait: 20)
          end
        end

        # Check if the MR is able to be merged
        # Waits up 10 seconds and returns false if the MR can't be merged
        def mergeable?
          # The merge button is enabled via JS, but `has_element?` calls
          # `wait_for_requests`, which should ensure the disabled/enabled
          # state of the element is reliable
          has_element?(:merge_button, disabled: false)
        end

        # Waits up 10 seconds and returns false if the Revert button is not enabled
        def revertible?
          has_element?(:revert_button, disabled: false, wait: 10)
        end

        # Waits up 60 seconds and raises an error if unable to merge.
        #
        # If a state is encountered in which a user would typically refresh the page, this will refresh the page and
        # then check again if it's ready to merge. For example, it will refresh if a new change was pushed and the page
        # needs to be refreshed to show the change.
        #
        # @param [Boolean] transient_test true if the current test is a transient test (default: false)
        def wait_until_ready_to_merge(transient_test: false)
          wait_until do
            has_element?(:merge_button)

            break true unless find_element(:merge_button).disabled?

            # If the widget shows "Merge blocked: new changes were just added" we can refresh the page and check again
            next false if has_element?(:head_mismatch_content)

            # Stop waiting if we're in a transient test. By this point we're in an unexpected state and should let the
            # test fail so we can investigate. If we're not in a transient test we keep trying until we reach timeout.
            next true unless transient_test

            QA::Runtime::Logger.debug("MR widget text: #{mr_widget_text}")

            false
          end
        end

        def rebase!
          # The rebase button is disabled on load
          wait_until do
            has_element?(:mr_rebase_button)
          end

          # The rebase button is enabled via JS
          wait_until(reload: false) do
            !find_element(:mr_rebase_button).disabled?
          end

          click_element(:mr_rebase_button)
        end

        def merge_immediately!
          retry_until(reload: true, sleep_interval: 1, max_attempts: 12) do
            if has_element?(:merge_moment_dropdown)
              click_element(:merge_moment_dropdown, skip_finished_loading_check: true)
              click_element(:merge_immediately_menu_item, skip_finished_loading_check: true)
            else
              click_element(:merge_button, skip_finished_loading_check: true)
            end

            merged?
          end
        end

        def try_to_merge!
          # Revisit after merge page re-architect is done https://gitlab.com/gitlab-org/gitlab/-/issues/300042
          # To remove page refresh logic if possible
          wait_until_ready_to_merge
          wait_until { !find_element(:merge_button).text.include?('when pipeline succeeds') } # rubocop:disable Rails/NegateInclude

          click_element(:merge_button)
        end

        def view_email_patches
          # Click by JS is needed to bypass the Moved MR actions popover
          # Change back to regular click_element when moved_mr_sidebar FF is removed
          # Rollout issue: https://gitlab.com/gitlab-org/gitlab/-/issues/385460
          click_by_javascript(find_element(:mr_code_dropdown))
          visit_link_in_element(:download_email_patches_menu_item)
        end

        def view_plain_diff
          # Click by JS is needed to bypass the Moved MR actions popover
          # Change back to regular click_element when moved_mr_sidebar FF is removed
          # Rollout issue: https://gitlab.com/gitlab-org/gitlab/-/issues/385460
          click_by_javascript(find_element(:mr_code_dropdown))
          visit_link_in_element(:download_plain_diff_menu_item)
        end

        def wait_for_merge_request_error_message
          wait_until(max_duration: 30, reload: false) do
            has_element?(:merge_request_error_content)
          end
        end

        def click_open_in_web_ide
          # Click by JS is needed to bypass the Moved MR actions popover
          # Change back to regular click_element when moved_mr_sidebar FF is removed
          # Rollout issue: https://gitlab.com/gitlab-org/gitlab/-/issues/385460
          click_by_javascript(find_element(:mr_code_dropdown))
          click_element(:open_in_web_ide_button)
          page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)
          wait_for_requests
        end

        def edit_file_in_web_ide(file_name)
          within_element(:file_title_container, file_name: file_name) do
            click_element(:dropdown_button)
            click_element(:edit_in_ide_button)
          end
          page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)
        end

        def add_suggestion_to_diff(suggestion, line)
          find("a[data-linenumber='#{line}']").hover
          click_element(:diff_comment_button)
          click_element(:suggestion_button)
          initial_content = find_element(:reply_field).value
          fill_element(:reply_field, '')
          fill_element(:reply_field, initial_content.gsub(/(```suggestion:-0\+0\n).*(\n```)/, "\\1#{suggestion}\\2"))
          click_element(:comment_now_button)
          wait_for_requests
        end

        def apply_suggestion_with_message(message)
          all_elements(:apply_suggestion_dropdown, minimum: 1).first.click
          fill_element(:commit_message_field, message)
          click_element(:commit_with_custom_message_button)
        end

        def add_suggestion_to_batch
          all_elements(:add_suggestion_batch_button, minimum: 1).first.click
        end

        def has_suggestions_applied?(count = 1)
          wait_until(reload: false) do
            has_no_element?(:applying_badge)
          end
          all_elements(:applied_badge, count: count)
        end

        def cherry_pick!
          click_element(:cherry_pick_button, Page::Component::CommitModal)
          click_element(:submit_commit_button)
        end

        def revert_change!
          # reload page when the revert modal occasionally doesn't appear in ee:large-setup job
          # https://gitlab.com/gitlab-org/gitlab/-/issues/386623 (transient issue)
          retry_on_exception(reload: true) do
            click_element(:revert_button, Page::Component::CommitModal)
          end
          click_element(:submit_commit_button)
        end

        def cancel_auto_merge!
          click_element(:cancel_auto_merge_button)
        end

        def mr_widget_text
          find_element(:mr_widget_content).text
        end
      end
    end
  end
end

QA::Page::MergeRequest::Show.prepend_mod_with('Page::MergeRequest::Show', namespace: QA)

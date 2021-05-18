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

        view 'app/assets/javascripts/batch_comments/components/publish_button.vue' do
          element :submit_review_button
        end

        view 'app/assets/javascripts/batch_comments/components/review_bar.vue' do
          element :review_bar_content
        end

        view 'app/assets/javascripts/diffs/components/compare_dropdown_layout.vue' do
          element :dropdown_content
        end

        view 'app/assets/javascripts/diffs/components/compare_versions.vue' do
          element :target_version_dropdown
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

        view 'app/assets/javascripts/vue_merge_request_widget/components/mr_widget_header.vue' do
          element :download_dropdown
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
          element :merged_status_content
          element :revert_button
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/states/mr_widget_rebase.vue' do
          element :mr_rebase_button
          element :no_fast_forward_message_content
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/states/ready_to_merge.vue' do
          element :merge_button
          element :fast_forward_message_content
          element :merge_moment_dropdown
          element :merge_immediately_menu_item
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/states/squash_before_merge.vue' do
          element :squash_checkbox
        end

        view 'app/assets/javascripts/vue_shared/components/markdown/apply_suggestion.vue' do
          element :apply_suggestion_dropdown
          element :commit_message_field
          element :commit_with_custom_message_button
        end

        view 'app/assets/javascripts/vue_shared/components/markdown/header.vue' do
          element :suggestion_button
        end

        view 'app/assets/javascripts/vue_shared/components/markdown/suggestion_diff_header.vue' do
          element :apply_suggestions_batch_button
          element :add_suggestion_batch_button
        end

        view 'app/views/projects/merge_requests/_description.html.haml' do
          element :description_content
        end

        view 'app/views/projects/merge_requests/_mr_box.html.haml' do
          element :title_content
        end

        view 'app/views/projects/merge_requests/_mr_title.html.haml' do
          element :edit_button
        end

        view 'app/views/projects/merge_requests/show.html.haml' do
          element :notes_tab
          element :commits_tab
          element :diffs_tab
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/states/mr_widget_auto_merge_enabled.vue' do
          element :cancel_auto_merge_button
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
          within_element(:review_bar_content) do
            click_element(:review_preview_dropdown)
            click_element(:submit_review_button)

            # After clicking the button, wait for it to disappear
            # before moving on to the next part of the test
            has_no_element?(:submit_review_button)
          end
        end

        def add_comment_to_diff(text)
          wait_until(sleep_interval: 5) do
            has_css?('a[data-linenumber="1"]')
          end
          all_elements(:new_diff_line_link, minimum: 1).first.hover
          click_element(:diff_comment_button)
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
          click_element(:diffs_tab)
          click_element(:dismiss_popover_button) if has_element?(:dismiss_popover_button, wait: 1)
        end

        def click_pipeline_link
          click_element(:pipeline_link)
        end

        def edit!
          click_element(:edit_button)
        end

        def fast_forward_possible?
          has_element?(:fast_forward_message_content)
        end

        def fast_forward_not_possible?
          has_element?(:no_fast_forward_message_content)
        end

        def has_file?(file_name)
          has_element?(:file_name_content, text: file_name)
        end

        def has_no_file?(file_name)
          has_no_element?(:file_name_content, text: file_name)
        end

        def has_merge_button?
          refresh

          has_element?(:merge_button)
        end

        def has_pipeline_status?(text)
          # Pipelines can be slow, so we wait a bit longer than the usual 10 seconds
          has_element?(:merge_request_pipeline_info_content, text: text, wait: 60)
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
          # Revisit after merge page re-architect is done https://gitlab.com/gitlab-org/gitlab/-/issues/300042
          # To remove page refresh logic if possible
          retry_until(max_attempts: 3, reload: true) do
            has_element?(:merged_status_content, text: 'The changes were merged into', wait: 20)
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

        # Waits up 60 seconds and raises an error if unable to merge
        def wait_until_ready_to_merge
          has_element?(:merge_button)

          # The merge button is enabled via JS
          wait_until(reload: false) do
            !find_element(:merge_button).disabled?
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

          success = wait_until do
            fast_forward_possible?
          end

          raise "Rebase did not appear to be successful" unless success
        end

        def try_to_merge!
          # Revisit after merge page re-architect is done https://gitlab.com/gitlab-org/gitlab/-/issues/300042
          # To remove page refresh logic if possible
          wait_until_ready_to_merge
          wait_until { !find_element(:merge_button).has_text?("when pipeline succeeds") }

          click_element(:merge_button)
        end

        def view_email_patches
          click_element(:download_dropdown)
          visit_link_in_element(:download_email_patches_menu_item)
        end

        def view_plain_diff
          click_element(:download_dropdown)
          visit_link_in_element(:download_plain_diff_menu_item)
        end

        def wait_for_merge_request_error_message
          wait_until(max_duration: 30, reload: false) do
            has_element?(:merge_request_error_content)
          end
        end

        def click_open_in_web_ide
          click_element(:open_in_web_ide_button)
          wait_for_requests
        end

        def edit_file_in_web_ide(file_name)
          within_element(:file_title_container, file_name: file_name) do
            click_element(:dropdown_button)
            click_element(:edit_in_ide_button)
          end
        end

        def add_suggestion_to_diff(suggestion, line)
          find("a[data-linenumber='#{line}']").hover
          click_element(:diff_comment_button)
          click_element(:suggestion_button)
          initial_content = find_element(:reply_field).value
          fill_element(:reply_field, '')
          fill_element(:reply_field, initial_content.gsub(/(```suggestion:-0\+0\n).*(\n```)/, "\\1#{suggestion}\\2"))
          click_element(:comment_now_button)
        end

        def apply_suggestion_with_message(message)
          click_element(:apply_suggestion_dropdown)
          fill_element(:commit_message_field, message)
          click_element(:commit_with_custom_message_button)
        end

        def add_suggestion_to_batch
          all_elements(:add_suggestion_batch_button, minimum: 1).first.click
        end

        def apply_suggestions_batch
          all_elements(:apply_suggestions_batch_button, minimum: 1).first.click
        end

        def cherry_pick!
          click_element(:cherry_pick_button, Page::Component::CommitModal)
          click_element(:submit_commit_button)
        end

        def revert_change!
          click_element(:revert_button, Page::Component::CommitModal)
          click_element(:submit_commit_button)
        end

        def cancel_auto_merge!
          click_element(:cancel_auto_merge_button)
        end
      end
    end
  end
end

QA::Page::MergeRequest::Show.prepend_mod_with('Page::MergeRequest::Show', namespace: QA)

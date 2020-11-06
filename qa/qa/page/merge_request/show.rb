# frozen_string_literal: true

module QA
  module Page
    module MergeRequest
      class Show < Page::Base
        include Page::Component::Note
        include Page::Component::Issuable::Sidebar

        view 'app/assets/javascripts/vue_merge_request_widget/components/mr_widget_header.vue' do
          element :download_dropdown
          element :download_email_patches
          element :download_plain_diff
          element :open_in_web_ide_button
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/mr_widget_pipeline.vue' do
          element :merge_request_pipeline_info_content
          element :pipeline_link
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/states/ready_to_merge.vue' do
          element :merge_button
          element :fast_forward_message, 'Fast-forward merge without a merge commit' # rubocop:disable QA/ElementWithPattern
          element :merge_moment_dropdown
          element :merge_immediately_option
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/states/mr_widget_merged.vue' do
          element :merged_status_content
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/states/mr_widget_failed_to_merge.vue' do
          element :merge_request_error_content
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/states/mr_widget_rebase.vue' do
          element :mr_rebase_button
          element :no_fast_forward_message, 'Fast-forward merge is not possible' # rubocop:disable QA/ElementWithPattern
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/states/squash_before_merge.vue' do
          element :squash_checkbox
        end

        view 'app/views/projects/merge_requests/show.html.haml' do
          element :notes_tab
          element :diffs_tab
        end

        view 'app/assets/javascripts/diffs/components/compare_dropdown_layout.vue' do
          element :dropdown_content
        end

        view 'app/assets/javascripts/diffs/components/compare_versions.vue' do
          element :target_version_dropdown
        end

        view 'app/assets/javascripts/diffs/components/diff_file_header.vue' do
          element :file_name_content
        end

        view 'app/assets/javascripts/diffs/components/inline_diff_table_row.vue' do
          element :new_diff_line
        end

        view 'app/views/projects/merge_requests/_mr_title.html.haml' do
          element :edit_button
        end

        view 'app/assets/javascripts/batch_comments/components/publish_button.vue' do
          element :submit_review
        end

        view 'app/assets/javascripts/batch_comments/components/review_bar.vue' do
          element :review_bar
        end

        view 'app/assets/javascripts/notes/components/note_form.vue' do
          element :unresolve_review_discussion_checkbox
          element :resolve_review_discussion_checkbox
          element :start_review_button
          element :comment_now_button
        end

        view 'app/assets/javascripts/batch_comments/components/preview_dropdown.vue' do
          element :review_preview_toggle
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

        def comment_now
          click_element(:comment_now_button)

          # After clicking the button, wait for it to disappear
          # before moving on to the next part of the test
          has_no_element?(:comment_now_button)
        end

        def version_dropdown_content
          find_element(:dropdown_content).text
        end

        def submit_pending_reviews
          within_element(:review_bar) do
            click_element(:review_preview_toggle)
            click_element(:submit_review)

            # After clicking the button, wait for it to disappear
            # before moving on to the next part of the test
            has_no_element?(:submit_review)
          end
        end

        def discard_pending_reviews
          within_element(:review_bar) do
            click_element(:discard_review)
          end
          click_element(:modal_delete_pending_comments)
        end

        def resolve_review_discussion
          scroll_to_element(:start_review_button)
          check_element(:resolve_review_discussion_checkbox)
        end

        def unresolve_review_discussion
          check_element(:unresolve_review_discussion_checkbox)
        end

        def add_comment_to_diff(text)
          wait_until(sleep_interval: 5) do
            has_css?('a[data-linenumber="1"]')
          end
          all_elements(:new_diff_line, minimum: 1).first.hover
          click_element(:diff_comment)
          fill_element(:reply_field, text)
        end

        def click_discussions_tab
          click_element(:notes_tab)

          wait_for_loading
        end

        def click_diffs_tab
          click_element(:diffs_tab)

          wait_for_loading

          click_element(:dismiss_popover_button) if has_element?(:dismiss_popover_button)
        end

        def click_pipeline_link
          click_element(:pipeline_link)
        end

        def edit!
          click_element(:edit_button)
        end

        def fast_forward_possible?
          has_no_text?('Fast-forward merge is not possible')
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
          has_element?(:title, text: title)
        end

        def has_description?(description)
          has_element?(:description, text: description)
        end

        def mark_to_squash
          # The squash checkbox is disabled on load
          wait_until do
            has_element?(:squash_checkbox)
          end

          # The squash checkbox is enabled via JS
          wait_until(reload: false) do
            !find_element(:squash_checkbox).disabled?
          end

          click_element(:squash_checkbox)
        end

        def merge!
          wait_until_ready_to_merge
          click_element(:merge_button)
          finished_loading?

          raise "Merge did not appear to be successful" unless merged?
        end

        def merge_immediately!
          click_element(:merge_moment_dropdown)
          click_element(:merge_immediately_option)
        end

        def merged?
          has_element?(:merged_status_content, text: 'The changes were merged into', wait: 60)
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
            has_text?('Fast-forward merge without a merge commit')
          end

          raise "Rebase did not appear to be successful" unless success
        end

        def try_to_merge!
          wait_until_ready_to_merge

          click_element(:merge_button)
        end

        def view_email_patches
          click_element(:download_dropdown)
          visit_link_in_element(:download_email_patches)
        end

        def view_plain_diff
          click_element(:download_dropdown)
          visit_link_in_element(:download_plain_diff)
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
      end
    end
  end
end

QA::Page::MergeRequest::Show.prepend_if_ee('QA::EE::Page::MergeRequest::Show')

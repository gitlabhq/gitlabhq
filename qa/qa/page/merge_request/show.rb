# frozen_string_literal: true

module QA
  module Page
    module MergeRequest
      class Show < Page::Base
        include Page::Component::Note

        view 'app/assets/javascripts/vue_merge_request_widget/components/mr_widget_header.vue' do
          element :dropdown_toggle
          element :download_email_patches
          element :download_plain_diff
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/mr_widget_pipeline.vue' do
          element :merge_request_pipeline_info_content
          element :pipeline_link
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/states/ready_to_merge.vue' do
          element :merge_button
          element :fast_forward_message, 'Fast-forward merge without a merge commit' # rubocop:disable QA/ElementWithPattern
          element :merge_moment_dropdown
          element :merge_when_pipeline_succeeds_option
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

        view 'app/assets/javascripts/diffs/components/diff_line_gutter_content.vue' do
          element :diff_comment
        end

        view 'app/assets/javascripts/diffs/components/inline_diff_table_row.vue' do
          element :new_diff_line
        end

        view 'app/views/shared/issuable/_sidebar.html.haml' do
          element :assignee_block
          element :labels_block
        end

        view 'app/views/projects/merge_requests/_mr_title.html.haml' do
          element :edit_button
        end

        def add_comment_to_diff(text)
          wait(interval: 5) do
            has_text?("No newline at end of file")
          end
          all_elements(:new_diff_line).first.hover
          click_element :diff_comment
          fill_element :reply_input, text
        end

        def click_discussions_tab
          click_element :notes_tab

          finished_loading?
        end

        def click_diffs_tab
          click_element :diffs_tab

          finished_loading?
        end

        def click_pipeline_link
          click_element :pipeline_link
        end

        def edit!
          click_element :edit_button
        end

        def fast_forward_possible?
          has_no_text?('Fast-forward merge is not possible')
        end

        def has_merge_button?
          refresh

          has_element?(:merge_button)
        end

        def has_assignee?(username)
          page.within(element_selector_css(:assignee_block)) do
            has_text?(username)
          end
        end

        def has_label?(label)
          within_element(:labels_block) do
            !!has_element?(:label, label_name: label)
          end
        end

        def has_pipeline_status?(text)
          # Pipelines can be slow, so we wait a bit longer than the usual 10 seconds
          has_element?(:merge_request_pipeline_info_content, text: text, wait: 30)
        end

        def has_title?(title)
          has_element?(:title, text: title)
        end

        def has_description?(description)
          has_element?(:description, text: description)
        end

        def mark_to_squash
          # The squash checkbox is disabled on load
          wait do
            has_element?(:squash_checkbox)
          end

          # The squash checkbox is enabled via JS
          wait(reload: false) do
            !find_element(:squash_checkbox).disabled?
          end

          click_element :squash_checkbox
        end

        def merge!
          click_element :merge_button if ready_to_merge?

          raise "Merge did not appear to be successful" unless merged?
        end

        def merged?
          has_element?(:merged_status_content, text: 'The changes were merged into', wait: 30)
        end

        def ready_to_merge?
          # The merge button is disabled on load
          wait do
            has_element?(:merge_button)
          end

          # The merge button is enabled via JS
          wait(reload: false) do
            !find_element(:merge_button).disabled?
          end
        end

        def rebase!
          # The rebase button is disabled on load
          wait do
            has_element?(:mr_rebase_button)
          end

          # The rebase button is enabled via JS
          wait(reload: false) do
            !find_element(:mr_rebase_button).disabled?
          end

          click_element :mr_rebase_button

          success = wait do
            has_text?('Fast-forward merge without a merge commit')
          end

          raise "Rebase did not appear to be successful" unless success
        end

        def try_to_merge!
          click_element :merge_button if ready_to_merge?
        end

        def view_email_patches
          click_element :dropdown_toggle
          visit_link_in_element(:download_email_patches)
        end

        def view_plain_diff
          click_element :dropdown_toggle
          visit_link_in_element(:download_plain_diff)
        end

        def wait_for_merge_request_error_message
          wait(max: 30, reload: false) do
            has_element?(:merge_request_error_content)
          end
        end
      end
    end
  end
end

QA::Page::MergeRequest::Show.prepend_if_ee('QA::EE::Page::MergeRequest::Show')

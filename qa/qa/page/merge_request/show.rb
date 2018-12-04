# frozen_string_literal: true

module QA
  module Page
    module MergeRequest
      class Show < Page::Base
        view 'app/assets/javascripts/vue_merge_request_widget/components/states/ready_to_merge.vue' do
          element :merge_button
          element :fast_forward_message, 'Fast-forward merge without a merge commit' # rubocop:disable QA/ElementWithPattern
          element :merge_moment_dropdown
          element :merge_when_pipeline_succeeds_option
          element :merge_immediately_option
        end

        view 'app/assets/javascripts/vue_merge_request_widget/components/states/mr_widget_merged.vue' do
          element :merged_status, 'The changes were merged into' # rubocop:disable QA/ElementWithPattern
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

        view 'app/assets/javascripts/notes/components/comment_form.vue' do
          element :note_dropdown
          element :discussion_option
        end

        view 'app/assets/javascripts/notes/components/note_form.vue' do
          element :reply_input
        end

        view 'app/assets/javascripts/notes/components/noteable_discussion.vue' do
          element :discussion_reply
        end

        view 'app/assets/javascripts/diffs/components/inline_diff_table_row.vue' do
          element :new_diff_line
        end

        view 'app/views/shared/issuable/_sidebar.html.haml' do
          element :labels_block
        end

        view 'app/views/projects/merge_requests/_mr_title.html.haml' do
          element :edit_button
        end

        def fast_forward_possible?
          !has_text?('Fast-forward merge is not possible')
        end

        def has_merge_button?
          refresh

          has_css?(element_selector_css(:merge_button))
        end

        def has_merge_options?
          has_css?(element_selector_css(:merge_moment_dropdown))
        end

        def merge_immediately
          if has_merge_options?
            click_element :merge_moment_dropdown
            click_element :merge_immediately_option
          else
            click_element :merge_button
          end
        end

        def rebase!
          # The rebase button is disabled on load
          wait do
            has_css?(element_selector_css(:mr_rebase_button))
          end

          # The rebase button is enabled via JS
          wait(reload: false) do
            !first(element_selector_css(:mr_rebase_button)).disabled?
          end

          click_element :mr_rebase_button

          wait(reload: false) do
            has_text?('Fast-forward merge without a merge commit')
          end
        end

        def has_label?(label)
          page.within(element_selector_css(:labels_block)) do
            element = find('span', text: label)
            !element.nil?
          end
        end

        def merge!
          # The merge button is disabled on load
          wait do
            has_css?(element_selector_css(:merge_button))
          end

          # The merge button is enabled via JS
          wait(reload: false) do
            !first(element_selector_css(:merge_button)).disabled?
          end

          merge_immediately

          wait(reload: false) do
            has_text?('The changes were merged into')
          end
        end

        def mark_to_squash
          # The squash checkbox is disabled on load
          wait do
            has_css?(element_selector_css(:squash_checkbox))
          end

          # The squash checkbox is enabled via JS
          wait(reload: false) do
            !first(element_selector_css(:squash_checkbox)).disabled?
          end

          click_element :squash_checkbox
        end

        def go_to_discussions_tab
          click_element :notes_tab
        end

        def go_to_diffs_tab
          click_element :diffs_tab
        end

        def add_comment_to_diff(text)
          wait(time: 5) do
            page.has_text?("No newline at end of file")
          end
          all_elements(:new_diff_line).first.hover
          click_element :diff_comment
          fill_element :reply_input, text
        end

        def start_discussion(text)
          fill_element :comment_input, text
          click_element :note_dropdown
          click_element :discussion_option
          click_element :comment_button
        end

        def reply_to_discussion(reply_text)
          all_elements(:discussion_reply).last.click
          fill_element :reply_input, reply_text
        end

        def edit!
          click_element :edit_button
        end
      end
    end
  end
end

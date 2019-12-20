# frozen_string_literal: true

module QA
  module Page
    module Project
      module Issue
        class Show < Page::Base
          include Page::Component::Issuable::Common
          include Page::Component::Note

          view 'app/assets/javascripts/notes/components/comment_form.vue' do
            element :comment_button
            element :comment_input
          end

          view 'app/assets/javascripts/notes/components/discussion_filter.vue' do
            element :discussion_filter, required: true
            element :filter_options
          end

          view 'app/assets/javascripts/notes/components/noteable_note.vue' do
            element :noteable_note_item
          end

          view 'app/assets/javascripts/sidebar/components/assignees/assignee_avatar.vue' do
            element :avatar_image
          end

          view 'app/assets/javascripts/sidebar/components/assignees/uncollapsed_assignee_list.vue' do
            element :more_assignees_link
          end

          view 'app/assets/javascripts/vue_shared/components/issue/related_issuable_item.vue' do
            element :remove_related_issue_button
          end

          view 'app/helpers/dropdowns_helper.rb' do
            element :dropdown_input_field
          end

          view 'app/views/shared/issuable/_close_reopen_button.html.haml' do
            element :close_issue_button
            element :reopen_issue_button
          end

          view 'app/views/shared/issuable/_sidebar.html.haml' do
            element :assignee_block
            element :labels_block
            element :edit_link_labels
            element :dropdown_menu_labels
            element :milestone_link
          end

          view 'app/views/shared/notes/_form.html.haml' do
            element :new_note_form, 'new-note' # rubocop:disable QA/ElementWithPattern
            element :new_note_form, 'attr: :note' # rubocop:disable QA/ElementWithPattern
          end

          def avatar_image_count
            wait_assignees_block_finish_loading do
              all_elements(:avatar_image).count
            end
          end

          def click_milestone_link
            click_element(:milestone_link)
          end

          def click_remove_related_issue_button
            click_element(:remove_related_issue_button)
          end

          def click_close_issue_button
            click_element :close_issue_button
          end

          # Adds a comment to an issue
          # attachment option should be an absolute path
          def comment(text, attachment: nil, filter: :all_activities)
            method("select_#{filter}_filter").call
            fill_element :comment_input, text

            unless attachment.nil?
              QA::Page::Component::Dropzone.new(self, '.new-note')
                .attach_file(attachment)
            end

            click_element :comment_button
          end

          def has_comment?(comment_text)
            wait(reload: false) do
              has_element?(:noteable_note_item, text: comment_text)
            end
          end

          def more_assignees_link
            find_element(:more_assignees_link)
          end

          def noteable_note_item
            find_element(:noteable_note_item)
          end

          def select_all_activities_filter
            select_filter_with_text('Show all activity')
          end

          def select_comments_only_filter
            select_filter_with_text('Show comments only')
          end

          def select_history_only_filter
            select_filter_with_text('Show history only')
          end

          def select_labels_and_refresh(labels)
            Support::Retrier.retry_until do
              click_element(:edit_link_labels)
              has_element?(:dropdown_menu_labels, text: labels.first)
            end

            labels.each do |label|
              within_element(:dropdown_menu_labels, text: label) do
                send_keys_to_element(:dropdown_input_field, [label, :enter])
              end
            end

            click_body

            labels.each do |label|
              has_element?(:labels_block, text: label)
            end

            refresh
          end

          def text_of_labels_block
            find_element(:labels_block)
          end

          def toggle_more_assignees_link
            click_element(:more_assignees_link)
          end

          private

          def select_filter_with_text(text)
            retry_on_exception do
              click_element(:title)
              click_element :discussion_filter
              find_element(:filter_options, text: text).click
            end
          end

          def wait_assignees_block_finish_loading
            within_element(:assignee_block) do
              wait(reload: false, max: 10, interval: 1) do
                finished_loading_block?
                yield
              end
            end
          end
        end
      end
    end
  end
end

QA::Page::Project::Issue::Show.prepend_if_ee('QA::EE::Page::Project::Issue::Show')

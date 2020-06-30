# frozen_string_literal: true

module QA
  module Page
    module Project
      module Issue
        class Show < Page::Base
          include Page::Component::Issuable::Common
          include Page::Component::Note
          include Page::Component::DesignManagement
          include Page::Component::Issuable::Sidebar

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

          view 'app/assets/javascripts/vue_shared/components/issue/related_issuable_item.vue' do
            element :remove_related_issue_button
          end

          view 'app/views/shared/issuable/_close_reopen_button.html.haml' do
            element :close_issue_button
            element :reopen_issue_button
          end

          view 'app/views/shared/notes/_form.html.haml' do
            element :new_note_form, 'new-note' # rubocop:disable QA/ElementWithPattern
            element :new_note_form, 'attr: :note' # rubocop:disable QA/ElementWithPattern
          end

          view 'app/views/projects/issues/_tabs.html.haml' do
            element :designs_tab_content
            element :designs_tab_link
            element :discussion_tab_content
            element :discussion_tab_link
          end

          def click_discussion_tab
            click_element(:discussion_tab_link)
            active_element?(:discussion_tab_content)
          end

          def click_designs_tab
            click_element(:designs_tab_link)
            active_element?(:designs_tab_content)
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
            fill_element :comment_input, "#{text}\n"

            unless attachment.nil?
              QA::Page::Component::Dropzone.new(self, '.new-note')
                .attach_file(attachment)
            end

            click_element :comment_button
          end

          def has_comment?(comment_text)
            has_element?(:noteable_note_item, text: comment_text, wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)
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

          private

          def select_filter_with_text(text)
            retry_on_exception do
              click_element(:title)
              click_element :discussion_filter
              find_element(:filter_options, text: text).click
            end
          end
        end
      end
    end
  end
end

QA::Page::Project::Issue::Show.prepend_if_ee('QA::EE::Page::Project::Issue::Show')

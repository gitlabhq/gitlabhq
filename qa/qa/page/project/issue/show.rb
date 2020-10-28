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
            element :comment_field
          end

          view 'app/assets/javascripts/notes/components/discussion_filter.vue' do
            element :discussion_filter_dropdown, required: true
            element :filter_menu_item
          end

          view 'app/assets/javascripts/notes/components/discussion_filter_note.vue' do
            element :discussion_filter_container
          end

          view 'app/assets/javascripts/notes/components/noteable_note.vue' do
            element :noteable_note_container
          end

          view 'app/assets/javascripts/notes/components/note_header.vue' do
            element :system_note_content
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

          view 'app/assets/javascripts/related_issues/components/add_issuable_form.vue' do
            element :add_issue_button
          end

          view 'app/assets/javascripts/related_issues/components/related_issuable_input.vue' do
            element :add_issue_field
          end

          view 'app/assets/javascripts/related_issues/components/related_issues_block.vue' do
            element :related_issues_plus_button
          end

          view 'app/assets/javascripts/related_issues/components/related_issues_list.vue' do
            element :related_issuable_content
            element :related_issues_loading_placeholder
          end

          def relate_issue(issue)
            click_element(:related_issues_plus_button)
            fill_element(:add_issue_field, issue.web_url)
            send_keys_to_element(:add_issue_field, :enter)
          end

          def related_issuable_item
            find_element(:related_issuable_content)
          end

          def wait_for_related_issues_to_load
            has_no_element?(:related_issues_loading_placeholder, wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)
          end

          def click_remove_related_issue_button
            retry_until(sleep_interval: 5) do
              click_element(:remove_related_issue_button)
              has_no_element?(:remove_related_issue_button, wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)
            end
          end

          def click_close_issue_button
            click_element :close_issue_button
          end

          # Adds a comment to an issue
          # attachment option should be an absolute path
          def comment(text, attachment: nil, filter: :all_activities)
            method("select_#{filter}_filter").call
            fill_element :comment_field, "#{text}\n"

            unless attachment.nil?
              QA::Page::Component::Dropzone.new(self, '.new-note')
                .attach_file(attachment)
            end

            click_element :comment_button
          end

          def has_comment?(comment_text)
            has_element?(:noteable_note_container, text: comment_text, wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)
          end

          def has_system_note?(note_text)
            has_element?(:system_note_content, text: note_text, wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)
          end

          def noteable_note_item
            find_element(:noteable_note_container)
          end

          def select_all_activities_filter
            select_filter_with_text('Show all activity')
          end

          def select_comments_only_filter
            select_filter_with_text('Show comments only')

            wait_until do
              has_no_element?(:system_note_content)
            end
          end

          def select_history_only_filter
            select_filter_with_text('Show history only')

            wait_until do
              has_element?(:discussion_filter_container) && has_no_element?(:noteable_note_container)
            end
          end

          def has_metrics_unfurled?
            has_element?(:prometheus_graph_widgets, wait: 30)
          end

          private

          def select_filter_with_text(text)
            retry_on_exception do
              click_element(:title)
              click_element :discussion_filter_dropdown
              find_element(:filter_menu_item, text: text).click

              wait_for_loading
            end
          end
        end
      end
    end
  end
end

QA::Page::Project::Issue::Show.prepend_if_ee('QA::EE::Page::Project::Issue::Show')

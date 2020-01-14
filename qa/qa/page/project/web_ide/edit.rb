# frozen_string_literal: true

module QA
  module Page
    module Project
      module WebIDE
        class Edit < Page::Base
          prepend Page::Component::WebIDE::Alert
          include Page::Component::DropdownFilter

          view 'app/assets/javascripts/ide/components/activity_bar.vue' do
            element :commit_mode_tab
          end

          view 'app/assets/javascripts/ide/components/ide_tree.vue' do
            element :new_file
          end

          view 'app/assets/javascripts/ide/components/ide_tree_list.vue' do
            element :file_list
          end

          view 'app/assets/javascripts/ide/components/new_dropdown/modal.vue' do
            element :full_file_path
            element :new_file_modal
            element :template_list
          end

          view 'app/assets/javascripts/ide/components/file_templates/bar.vue' do
            element :file_templates_bar
            element :file_template_dropdown
          end

          view 'app/assets/javascripts/ide/components/file_templates/dropdown.vue' do
            element :dropdown_filter_input
          end

          view 'app/assets/javascripts/ide/components/commit_sidebar/actions.vue' do
            element :commit_to_current_branch_radio
          end

          view 'app/assets/javascripts/ide/components/commit_sidebar/form.vue' do
            element :begin_commit_button
            element :commit_button
          end

          view 'app/assets/javascripts/ide/components/commit_sidebar/new_merge_request_option.vue' do
            element :start_new_mr_checkbox
          end

          def has_file?(file_name)
            within_element(:file_list) do
              page.has_content? file_name
            end
          end

          def create_new_file_from_template(file_name, template)
            click_element :new_file

            # Wait for the modal animation to complete before clicking on the file name
            wait_for_animated_element(:new_file_modal)

            within_element(:template_list) do
              click_on file_name
            rescue Capybara::ElementNotFound
              raise ElementNotFound, %Q(Couldn't find file template named "#{file_name}". Please confirm that it is a valid option.)
            end

            # Wait for the modal to fade out too
            has_no_element?(:new_file_modal)

            wait(reload: false) do
              within_element(:file_templates_bar) do
                click_element :file_template_dropdown
                fill_element :dropdown_filter_input, template

                begin
                  click_on template
                rescue Capybara::ElementNotFound
                  raise ElementNotFound, %Q(Couldn't find template "#{template}" for #{file_name}. Please confirm that it exists in the list of templates.)
                end
              end
            end
          end

          def commit_changes
            # Clicking :begin_commit_button the first time switches from the
            # edit to the commit view
            click_element :begin_commit_button
            active_element? :commit_mode_tab

            # We need to click :begin_commit_button again
            click_element :begin_commit_button

            # After clicking :begin_commit_button the 2nd time there is an
            # animation that hides :begin_commit_button and shows :commit_button
            #
            # Wait for the animation to complete before clicking :commit_button
            # otherwise the click will quietly do nothing.
            wait(reload: false) do
              has_no_element?(:begin_commit_button) &&
                has_element?(:commit_button)
            end

            # At this point we're ready to commit and the button should be
            # labelled "Stage & Commit"
            #
            # Click :commit_button and keep retrying just in case part of the
            # animation is still in process even when the buttons have the
            # expected visibility.
            commit_success_msg_shown = retry_until(sleep_interval: 5) do
              click_element(:commit_to_current_branch_radio) if has_element?(:commit_to_current_branch_radio)
              click_element(:commit_button) if has_element?(:commit_button)

              wait(reload: false) do
                has_text?('Your changes have been committed')
              end
            end

            raise "The changes do not appear to have been committed successfully." unless commit_success_msg_shown
          end
        end
      end
    end
  end
end

QA::Page::Project::WebIDE::Edit.prepend_if_ee('QA::EE::Page::Component::WebIDE::WebTerminalPanel')

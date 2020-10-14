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
            element :edit_mode_tab
          end

          view 'app/assets/javascripts/ide/components/ide_status_bar.vue' do
            element :commit_sha_content
          end

          view 'app/assets/javascripts/ide/components/ide_tree.vue' do
            element :new_file
          end

          view 'app/assets/javascripts/ide/components/ide_tree_list.vue' do
            element :file_list
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

          view 'app/assets/javascripts/ide/components/repo_editor.vue' do
            element :editor_container
          end

          view 'app/assets/javascripts/ide/components/ide.vue' do
            element :first_file_button
          end

          view 'app/assets/javascripts/vue_shared/components/file_row.vue' do
            element :file_name_content
          end

          view 'app/assets/javascripts/ide/components/new_dropdown/index.vue' do
            element :dropdown_button
            element :rename_move_button
          end

          view 'app/views/shared/_confirm_fork_modal.html.haml' do
            element :fork_project_button
            element :confirm_fork_modal
          end

          view 'app/assets/javascripts/ide/components/ide_project_header.vue' do
            element :project_path_content
          end

          view 'app/assets/javascripts/ide/components/commit_sidebar/message_field.vue' do
            element :ide_commit_message_field
          end

          def has_file?(file_name)
            within_element(:file_list) do
              page.has_content? file_name
            end
          end

          def has_project_path?(project_path)
            has_element?(:project_path_content, project_path: project_path)
          end

          def go_to_project
            click_element(:project_path_content, Page::Project::Show)
          end

          def create_new_file_from_template(file_name, template)
            click_element(:new_file, Page::Component::WebIDE::Modal::CreateNewFile)

            within_element(:template_list) do
              click_on file_name
            rescue Capybara::ElementNotFound
              raise ElementNotFound, %Q(Couldn't find file template named "#{file_name}". Please confirm that it is a valid option.)
            end

            # Wait for the modal to fade out too
            has_no_element?(:new_file_modal)

            wait_until(reload: false) do
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

          def commit_sha
            return unless has_element?(:commit_sha_content, wait: 0)

            find_element(:commit_sha_content).text
          end

          def commit_changes(commit_message = nil, open_merge_request: false)
            # Clicking :begin_commit_button switches from the
            # edit to the commit view
            click_element(:begin_commit_button)
            active_element?(:commit_mode_tab)

            original_commit = commit_sha

            # After clicking :begin_commit_button, there is an animation
            # that hides :begin_commit_button and shows :commit_button
            #
            # Wait for the animation to complete before clicking :commit_button
            # otherwise the click will quietly do nothing.
            wait_until(reload: false) do
              has_no_element?(:begin_commit_button) &&
                has_element?(:commit_button)
            end

            if commit_message
              fill_element(:ide_commit_message_field, commit_message)
            end

            if open_merge_request
              click_element(:commit_button, Page::MergeRequest::New)
            else
              # Click :commit_button and keep retrying just in case part of the
              # animation is still in process even when the buttons have the
              # expected visibility.
              commit_success = retry_until(sleep_interval: 5) do
                click_element(:commit_to_current_branch_radio) if has_element?(:commit_to_current_branch_radio)
                click_element(:commit_button) if has_element?(:commit_button)

                # If this is the first commit, the commit SHA only appears after reloading
                wait_until(reload: true) do
                  active_element?(:edit_mode_tab) && commit_sha != original_commit
                end
              end

              raise "The changes do not appear to have been committed successfully." unless commit_success
            end
          end

          def add_to_modified_content(content)
            finished_loading?
            modified_text_area.click
            modified_text_area.set content
          end

          def modified_text_area
            wait_for_animated_element(:editor_container)
            within_element(:editor_container) do
              find('.modified textarea.inputarea')
            end
          end

          def create_first_file(file_name)
            click_element(:first_file_button, Page::Component::WebIDE::Modal::CreateNewFile)
            fill_element(:file_name_field, file_name)
            click_button('Create file')
          end

          def add_file(file_name, file_text)
            click_element(:new_file, Page::Component::WebIDE::Modal::CreateNewFile)
            fill_element(:file_name_field, file_name)
            click_button('Create file')
            wait_until(reload: false) { has_file?(file_name) }
            within_element(:editor_container) do
              find('textarea.inputarea').click.set(file_text)
            end
          end

          def rename_file(file_name, new_file_name)
            click_element(:file_name_content, text: file_name)
            click_element(:dropdown_button)
            click_element(:rename_move_button, Page::Component::WebIDE::Modal::CreateNewFile)
            fill_element(:file_name_field, new_file_name)
            click_button('Rename file')
          end

          def fork_project!
            wait_until(reload: false) do
              has_element?(:confirm_fork_modal)
            end
            click_element(:fork_project_button)
            # wait for the fork to be created
            wait_until(reload: true) do
              has_element?(:file_list)
            end
          end
        end
      end
    end
  end
end

QA::Page::Project::WebIDE::Edit.prepend_if_ee('QA::EE::Page::Component::WebIDE::WebTerminalPanel')

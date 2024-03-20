# frozen_string_literal: true

# VSCode WebIDE is built off an iFrame application therefore we are unable to use `data-testids`
module QA
  module Page
    module Project
      module WebIDE
        class VSCode < Page::Base
          view 'app/views/shared/_broadcast_message.html.haml' do
            element 'broadcast-notification-container'
            element 'close-button'
          end

          def has_file_explorer?
            has_element?('div[aria-label="Files Explorer"]')
          end

          def right_click_file_explorer
            page.find('.explorer-folders-view', visible: true).right_click
          end

          def has_file?(file_name)
            has_element?("div[aria-label='#{file_name}']")
          end

          def open_file_from_explorer(file_name)
            click_element("div[aria-label='#{file_name}']")
          end

          def click_inside_editor_frame
            click_element('.monaco-editor')
          end

          def within_file_editor(&block)
            within_element('.monaco-editor .monaco-scrollable-element', &block)
          end

          def has_right_click_menu_item?
            has_element?('div.menu-item-check')
          end

          def click_menu_item(item)
            click_element("li[title='#{item}']")
          end

          def click_upload_menu_item
            click_element('span[aria-label="Upload..."]')
          end

          def enter_text_for_input(name)
            find_element('input[type="text"]')
            send_keys(name, :enter)
          end

          def enter_file_input(file)
            find_element('input[type="file"]', visible: false).send_keys(file)
          end

          def has_commit_pending_tab?
            has_element?('.scm-viewlet-label')
          end

          def click_commit_pending_tab
            click_element('.scm-viewlet-label', visible: true)
          end

          def click_commit_tab
            if has_element?('.codicon-source-control-view-icon + .badge')
              click_element('.codicon-source-control-view-icon + .badge')
            else
              click_element('.codicon-source-control-view-icon')
            end
          end

          def has_commit_message_box?
            has_element?('div[aria-label="Source Control Input"]')
          end

          def enter_commit_message(message)
            within_element('div[aria-label="Source Control Input"]') do
              find_element('.view-line').click
              send_keys(message)
            end
          end

          def click_commit_button
            click_element('div[aria-label="Commit to \'main\'"]')
          end

          def has_notification_box?
            has_element?('.monaco-dialog-box')
          end

          def click_new_branch
            click_element('.monaco-button[title="Create new branch"]')
          end

          def click_continue_with_existing_branch
            click_element('.monaco-button[title="Continue"]')
          end

          def has_branch_input_field?
            has_element?('input[aria-label="input"]')
          end

          def has_committed_successfully?
            has_element?('.span[title="Success! Your changes have been committed."]')
          end

          def has_message?(content)
            within_vscode_editor do
              has_text?(content)
            end
          end

          def close_ide_tab
            page.execute_script "window.close();" if page.current_url.include?('ide')
          end

          def ide_tab_closed?
            within_vscode_editor do
              has_file_explorer?
            end
          end

          def within_vscode_editor(&block)
            iframe = find('#ide iframe')
            page.within_frame(iframe, &block)
          end

          def within_vscode_duo_chat(&block)
            within_vscode_editor do
              within_frame(all(:frame, class: 'webview', visible: false).last) do
                within_frame(:frame, &block)
              end
            end
          end

          def switch_to_original_window
            page.driver.browser.switch_to.window(page.driver.browser.window_handles.first)
          end

          def create_new_file_from_template(filename, template)
            within_vscode_editor do
              Support::Waiter.wait_until(max_duration: 20, retry_on_exception: true) do
                click_menu_item("New File...")
                enter_text_for_input(filename)
                page.within('div.editor-container') do
                  page.find('textarea.inputarea.monaco-mouse-cursor-text').send_keys(template)
                end
                has_text?(filename)
              end
            end
          end

          # Used for stablility, due to feature_caching of vscode_web_ide
          def wait_for_ide_to_load
            page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)
            # On test environments we have a broadcast message that can cover the buttons
            if has_element?('broadcast-notification-container', wait: 5)
              within_element('broadcast-notification-container') do
                click_element('close-button')
              end
            end

            Support::WaitForRequests.wait_for_requests(finish_loading_wait: 30)
            Support::Waiter.wait_until(max_duration: 60, reload_page: page, retry_on_exception: true) do
              within_vscode_editor do
                # Check for webide file_explorer element
                has_file_explorer?
              end
            end
          end

          def create_new_folder(folder_name)
            create_item("New Folder...", folder_name)
          end

          def create_new_file(file_name)
            create_item("New File...", file_name)
          end

          def commit_and_push_to_new_branch(file_name)
            commit_toggle(file_name)
            push_to_new_branch
          end

          def commit_and_push_to_existing_branch(file_name)
            commit_toggle(file_name)
            push_to_existing_branch
          end

          def commit_toggle(message)
            within_vscode_editor do
              if has_commit_pending_tab?
                click_commit_pending_tab
              else
                click_commit_tab
              end

              has_commit_message_box?
              enter_commit_message(message)
              has_text?(message)
              click_commit_button
              has_notification_box?
            end
          end

          def push_to_existing_branch
            within_vscode_editor do
              click_continue_with_existing_branch
              has_committed_successfully?
            end
          end

          def push_to_new_branch
            within_vscode_editor do
              page.find('.monaco-button[title="Create new branch"]').click
              has_branch_input_field?
              # Typing enter to 'New branch name' popup to take the default branch name
              send_keys(:enter)
              has_committed_successfully?
            end
          end

          def create_merge_request
            within_vscode_editor do
              within_element('.notification-toast-container') do
                has_element?('div[title="GitLab Web IDE Extension (Extension)"]')
                click_element('.monaco-text-button[title="Create MR"]')
              end
            end
          end

          def upload_file(file_path)
            within_vscode_editor do
              # VSCode eagerly removes the input[type='file'] from click on Upload.
              # We need to execute a script on the iframe to stub out the iframes body.removeChild to add it back in.
              page.execute_script("document.body.removeChild = function(){};")

              # Use for stability, WebIDE inside an iframe is finnicky, webdriver sometimes moves too fast
              Support::Retrier.retry_until(
                max_attempts: 5, retry_on_exception: true, sleep_interval: 2
              ) do
                right_click_file_explorer
                has_right_click_menu_item?
                click_upload_menu_item
                enter_file_input(file_path)
              end
              # Wait for the file to be uploaded
              has_text?(file_path)
            end
          end

          def add_prompt_into_a_file(file_name, prompt_data, wait_for_code_suggestions: true)
            within_vscode_editor do
              open_file_from_explorer(file_name)
              click_inside_editor_frame
              within_file_editor do
                wait_until_code_suggestions_enabled if wait_for_code_suggestions
                send_keys(:enter, :enter)

                # Send keys one at a time to allow suggestions request to be triggered
                prompt_data.each_char { |c| send_keys(c) }
              end
            end
          end

          def wait_for_code_suggestion
            within_vscode_editor do
              within_file_editor do
                wait_until(reload: false, max_duration: 30, message: 'Waiting for Code Suggestion to start loading') do
                  has_code_suggestions_status?('loading')
                end

                # Wait for code suggestion to finish loading
                wait_until_code_suggestions_enabled
              end
            end
          end

          def accept_code_suggestion
            within_vscode_editor do
              within_file_editor do
                send_keys(:tab)
              end
            end
          end

          def editor_content_length
            within_vscode_editor do
              within_file_editor do
                page.text.length
              end
            end
          end

          def has_code_suggestions_disabled?
            within_vscode_editor do
              within_file_editor do
                has_code_suggestions_status_without_error?('disabled')
              end
            end
          end

          def open_duo_chat
            within_vscode_editor do
              click_element('a[aria-label="GitLab Duo Chat"]', wait: 60)
            end
          end

          private

          def create_item(click_item, item_name)
            within_vscode_editor do
              # Use for stability, WebIDE inside an iframe is finnicky, webdriver sometimes moves too fast
              Support::Waiter.wait_until(max_duration: 20, retry_on_exception: true) do
                click_menu_item(click_item)
                # Verify the button is triggered and textbox is waiting for input
                enter_text_for_input(item_name)
                has_text?(item_name)
              end
            end
          end

          def code_suggestions_icon_selector(status)
            "#GitLab\\.gitlab-workflow\\.gl\\.status\\.code_suggestions[aria-label*=#{status.downcase}]"
          end

          def has_code_suggestions_status?(status)
            page.document.has_css?(code_suggestions_icon_selector(status))
          end

          def has_code_suggestions_error?
            !page.document.has_no_css?(code_suggestions_icon_selector('error'))
          end

          def code_suggestions_error
            page.document.find(code_suggestions_icon_selector('error'))['aria-label']
          end

          def has_code_suggestions_status_without_error?(status)
            raise code_suggestions_error if has_code_suggestions_error?

            has_code_suggestions_status?(status)
          end

          def wait_until_code_suggestions_enabled
            wait_until(reload: false, max_duration: 30, skip_finished_loading_check_on_refresh: true,
              message: 'Wait for Code Suggestions extension to be enabled') do
              has_code_suggestions_status_without_error?('enabled')
            end
          end
        end
      end
    end
  end
end

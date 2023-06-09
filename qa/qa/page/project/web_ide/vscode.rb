# frozen_string_literal: true

# VSCode WebIDE is built off an iFrame application therefore we are unable to use `qa-selectors`
module QA
  module Page
    module Project
      module WebIDE
        class VSCode < Page::Base
          view 'app/views/shared/_broadcast_message.html.haml' do
            element :broadcast_notification_container
            element :close_button
          end

          def has_file_explorer?
            page.has_css?('.explorer-folders-view', visible: true)
          end

          def right_click_file_explorer
            page.find('.explorer-folders-view', visible: true).right_click
          end

          def has_new_folder_menu_item?
            page.has_css?('[aria-label="New Folder..."]', visible: true)
          end

          def click_new_folder_menu_item
            page.find('[aria-label="New Folder..."]').click
          end

          def enter_new_folder_text_input(name)
            page.find('.explorer-item-edited', visible: true)
            send_keys(name, :enter)
          end

          def has_upload_menu_item?
            page.has_css?('[aria-label="Upload..."]', visible: true)
          end

          def click_upload_menu_item
            page.find('[aria-label="Upload..."]').click
          end

          def enter_file_input(file)
            page.find('input[type="file"]', visible: false).send_keys(file)
          end

          def has_commit_pending_tab?
            page.has_css?('.scm-viewlet-label', visible: true)
          end

          def click_commit_pending_tab
            page.find('.scm-viewlet-label', visible: true).click
          end

          def click_commit_tab
            page.find('a.codicon-source-control-view-icon', visible: true).click
          end

          def has_commit_message_box?
            page.has_css?('div.view-lines.monaco-mouse-cursor-text', visible: true)
          end

          def enter_commit_message(message)
            page.find('div.view-lines.monaco-mouse-cursor-text', visible: true).send_keys(message)
          end

          def click_commit_button
            page.find('a.monaco-text-button', visible: true).click
          end

          def has_notification_box?
            page.has_css?('a.monaco-text-button', visible: true)
          end

          def create_merge_request
            Support::Waiter.wait_until(max_duration: 10, retry_on_exception: true) do
              within_vscode_editor do
                page.find('.monaco-button[title="Create MR"]').click
              end
            end
          end

          def click_new_branch
            page.find('.monaco-button[title="Create new branch"]').click
          end

          def has_branch_input_field?
            page.has_css?('.monaco-findInput', visible: true)
          end

          def has_message?(content)
            within_vscode_editor do
              page.has_content?(content)
            end
          end

          def within_vscode_editor(&block)
            iframe = find('#ide iframe')
            page.within_frame(iframe, &block)
          end

          # Used for stablility, due to feature_caching of vscode_web_ide
          def wait_for_ide_to_load
            page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)
            # On test environments we have a broadcast message that can cover the buttons
            if has_element?(:broadcast_notification_container, wait: 5)
              within_element(:broadcast_notification_container) do
                click_element(:close_button)
              end
            end

            wait_for_requests
            Support::Waiter.wait_until(max_duration: 10, reload_page: page, retry_on_exception: true) do
              within_vscode_editor do
                # Check for webide file_explorer element
                has_file_explorer?
              end
            end
          end

          def create_new_folder(name)
            within_vscode_editor do
              right_click_file_explorer
              has_new_folder_menu_item?

              # Use for stability, WebIDE inside an iframe is finnicky, webdriver sometimes moves too fast
              Support::Waiter.wait_until(max_duration: 20, retry_on_exception: true) do
                click_new_folder_menu_item
                # Verify New Folder button is triggered and textbox is waiting for input
                enter_new_folder_text_input(name)
                page.has_content?(name)
              end
            end
          end

          def commit_and_push(file_name)
            commit_toggle(file_name)
            push_to_new_branch
          end

          def commit_toggle(message)
            within_vscode_editor do
              if has_commit_pending_tab?
                click_commit_pending_tab
              else
                click_commit_tab
              end

              has_commit_message_box?
              send_keys(message)
              page.has_content?(message)
              click_commit_button
              has_notification_box?
            end
          end

          def push_to_new_branch
            within_vscode_editor do
              click_new_branch
              has_branch_input_field?
              # Typing enter to 'New branch name' popup to take the default branch name
              send_keys(:enter)
            end
          end

          def upload_file(file_path)
            wait_for_ide_to_load
            within_vscode_editor do
              # VSCode eagerly removes the input[type='file'] from click on Upload.
              # We need to execute a script on the iframe to stub out the iframes body.removeChild to add it back in.
              page.execute_script("document.body.removeChild = function(){};")

              right_click_file_explorer
              has_upload_menu_item?

              # Use for stability, WebIDE inside an iframe is finnicky, webdriver sometimes moves too fast
              Support::Waiter.wait_until(max_duration: 20, retry_on_exception: true) do
                click_upload_menu_item
                enter_file_input(file_path)
              end
            end
          end
        end
      end
    end
  end
end

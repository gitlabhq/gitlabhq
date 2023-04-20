# frozen_string_literal: true

# VSCode WebIDE is built off an iFrame application therefore we are uanble to use `qa-selectors`
module QA
  module Page
    module Project
      module WebIDE
        class VSCode < Page::Base
          # Use to Pass Test::Sanity::Selectors temporarily until iframe [data-qa-* selector added
          view 'app/views/shared/_broadcast_message.html.haml' do
            element :broadcast_notification_container
            element :close_button
          end

          # Used for stablility, due to feature_caching of vscode_web_ide
          def wait_for_ide_to_load
            page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)
            wait_for_requests
            Support::Waiter.wait_until(max_duration: 60, reload_page: page, retry_on_exception: true) do
              within_vscode_editor do
                # vscode file_explorer element
                page.has_css?('.explorer-folders-view', visible: true)
              end
            end
          end

          def within_vscode_editor(&block)
            iframe = find('#ide iframe')
            page.within_frame(iframe, &block)
          end

          def create_new_folder(name)
            within_vscode_editor do
              # Use for stability, WebIDE inside an iframe is finnicky
              Support::Waiter.wait_until(max_duration: 60, retry_on_exception: true) do
                page.find('.explorer-folders-view').right_click
                # new_folder_button
                page.has_css?('[aria-label="New Folder..."]', visible: true)
              end

              # Additonal wait for stability, webdriver sometimes moves too fast
              Support::Waiter.wait_until(max_duration: 60, retry_on_exception: true) do
                page.find('[aria-label="New Folder..."]').click
                # Verify New Folder button is triggered and textbox is waiting for input
                page.find('.explorer-item-edited', visible: true)
                send_keys(name, :enter)
                page.has_content?(name)
              end
            end
          end

          def commit_and_push(folder_name)
            within_vscode_editor do
              # Commit Tab
              page.find('a.codicon-source-control-view-icon').click
              send_keys(folder_name)
              page.has_content?(folder_name)

              # Commit Button
              page.find('a.monaco-text-button').click
              page.has_css?('.notification-list-item-details-row', visible: true)
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module QA
  module Vendor
    module Slack
      module Page
        class Chat < Vendor::Page::Base
          include Slack::Mixins::GitlabApp

          def skip_download_screen
            skip_download_selector = "[data-qa='continue_in_browser']"

            wait_for_text('download the Slack app')

            find(skip_download_selector).click if has_element?(skip_download_selector, wait: 1)
          end

          # @param [Array<String>] lines - messages to send
          # @param [String] channel to send message to
          def send_message_to_channel(lines, channel:)
            go_to_channel(channel)

            find("[data-qa='message_input']").click

            line = lines.shift

            while line
              send_keys(line)
              wait_for_text(line)

              send_keys([:shift, :enter]) unless lines.empty?

              line = lines.shift
            end

            send_keys(:enter)
          end

          # @param [String] line of text to wait for in chat
          def wait_for_text(line)
            Support::Waiter.wait_until(max_duration: 3, raise_on_failure: false) do
              page.text.include?(line)
            end
          end

          # @param [String] channel_name to visit
          def go_to_channel(channel_name)
            channel = messages.find do |msg|
              msg.text == channel_name
            end

            channel.click
          end

          def click_connect_account_link
            connect_account_messages = messages(text: /connect your GitLab account/i)

            connect_account_message = connect_account_messages.last.find("a[href*='staging-ref'")

            connect_account_message.scroll_to(:top)
            connect_account_message.click
          end

          # @param [Hash] opts to include when finding all message elements
          def messages(**opts)
            find_all("[data-qa='virtual-list-item']", **opts)
          end
        end
      end
    end
  end
end

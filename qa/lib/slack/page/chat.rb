# frozen_string_literal: true

module Slack
  module Page
    class Chat < Chemlab::Page
      include Mixins::Browser
      include Mixins::GitlabApp

      div :message_field, data_qa: 'message_input'
      button :connect_gitlab_button, visible_text: /Connect your GitLab account/
      button :skip_download_slack_button, data_qa: 'continue_in_browser'

      def skip_download_screen
        wait_for_text('download the Slack app')

        skip_download_slack_button_element.click if skip_download_slack_button_element.exists?
      end

      # @param [Array<String>] lines - messages to send
      # @param [String] channel to send message to
      def send_message_to_channel(lines, channel:)
        go_to_channel(channel)

        message_field_element.focus
        message_field_element.click

        while line = lines.shift
          browser.send_keys(line)
          wait_for_text(line)

          browser.send_keys([:shift, :enter]) unless lines.empty?
        end

        browser.send_keys(:enter)
      end

      def wait_for_text(line)
        QA::Support::Waiter.wait_until(max_duration: 3, raise_on_failure: false) do
          browser.text.include?(line)
        end
      end

      def go_to_channel(channel)
        menu_item = messages.find do |div|
          div.text == channel
        end
        menu_item.click
      end

      def click_connect_account_link
        divs = messages(visible_text: /connect your GitLab account/i)
        el = divs.last.a(href: /staging-ref/)
        el.scroll.to(:top)
        el.click
      end

      def messages(**opts)
        browser.divs(data_qa: 'virtual-list-item', **opts)
      end

      def gitlab_app_home
        browser.divs(data_qa: 'channel_item_container').find do |el|
          el.text == 'GitLab'
        end
      end
    end
  end
end

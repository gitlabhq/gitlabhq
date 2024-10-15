# frozen_string_literal: true

module QA
  module Flow
    module Integrations
      module Slack
        extend self

        # Need to sign in for this method
        # @param [QA::Resource::Project]
        def start_slack_install(project)
          project.visit!

          Page::Project::Menu.perform do |project_menu_page|
            project_menu_page.click_project
            project_menu_page.go_to_integrations_settings
          end

          Page::Project::Settings::Integrations.perform(&:click_slack_application_link)

          Page::Project::Settings::Services::Slack.perform(&:install_slack)
          Vendor::Slack::Page::OAuth.perform(&:submit_oauth)
        end

        # @param [QA::Resource::Project] project
        # @option [String | Nil] channel
        # @return [Boolean] is this account already authorized?
        def start_gitlab_connect(project, channel: nil)
          Vendor::Slack::Page::Chat.perform do |chat_page|
            # sometimes Slack will present a blocking page
            # for downloading the app instead of using a browser
            chat_page.skip_download_screen

            lines = ["/staging-gitlab #{project.path_with_namespace} issue show 1"]
            chat_page.send_message_to_channel(lines, channel: channel)

            # The only way to know if we are authorized is to send a slash command to the channel.
            # If the account / chat_name is already authorized, the Slack app will try to look up the issue
            # and return a 404 because it doesn't exist
            Support::Waiter.wait_until(max_duration: 4, raise_on_failure: false) do
              chat_page.messages.last.text =~ /connect your GitLab account|404 not found!/i
            end

            break(true) if /404 not found!/i.match?(chat_page.messages.last.text)

            chat_page.click_connect_account_link

            false
          end
        end
      end
    end
  end
end

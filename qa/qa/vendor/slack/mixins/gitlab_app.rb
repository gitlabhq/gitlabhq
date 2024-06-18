# frozen_string_literal: true

module QA
  module Vendor
    module Slack
      module Mixins
        module GitlabApp
          # @param [QA::Resource::Project] project
          # @param [String] channel
          # @param [String] title
          # @param [String] description
          def create_issue(project, channel:, title:, description:)
            lines = [
              "/staging-gitlab #{project.path_with_namespace} issue new #{title}",
              description
            ]

            send_message_to_channel(lines, channel: channel)
          end

          # @param [QA::Resource::Project] project
          # @param [QA::Resource::Project] target
          # @param [String] id
          # @param [String] channel
          def move_issue(project, target, id:, channel:)
            line = "/staging-gitlab #{project.path_with_namespace} issue move #{id} to #{target.path_with_namespace}"
            send_message_to_channel([line], channel: channel)
          end

          # @param [QA::Resource::Project] project
          # @param [String] id
          # @param [String] channel
          def show_issue(project, id:, channel:)
            send_message_to_channel(
              ["/staging-gitlab #{project.path_with_namespace} issue show #{id}"],
              channel: channel
            )
          end

          # @param [QA::Resource::Project] project
          # @param [String] id
          # @param [String] channel
          def close_issue(project, id:, channel:)
            send_message_to_channel(
              ["/staging-gitlab #{project.path_with_namespace} issue close #{id}"],
              channel: channel
            )
          end

          # @param [QA::Resource::Project] project
          # @param [String] channel
          # @param [String] id
          # @param [String] comment
          def comment_on_issue(project, channel:, id:, comment:)
            command = "/staging-gitlab #{project.path_with_namespace} issue comment #{id}"
            send_message_to_channel([command, comment], channel: channel)
          end
        end
      end
    end
  end
end

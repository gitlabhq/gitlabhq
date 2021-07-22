# frozen_string_literal: true

module Gitlab
  module SlashCommands
    module Presenters
      class Help < Presenters::Base
        def initialize(project, commands)
          @project = project
          @commands = commands
        end

        def present(trigger, text)
          ephemeral_response(text: help_message(trigger, text))
        end

        private

        def help_message(trigger, text)
          unless @commands.present?
            return <<~MESSAGE
              This chatops integration does not have any commands that can be
              executed.

              #{help_footer}
            MESSAGE
          end

          if text.start_with?('help')
            <<~MESSAGE
              #{full_commands_message(trigger)}

              #{help_footer}
            MESSAGE
          else
            <<~MESSAGE
              The specified command is not valid.

              #{full_commands_message(trigger)}

              #{help_footer}
            MESSAGE
          end
        end

        def help_footer
          message = @project ? project_info : ''
          message += <<~MESSAGE
             *Documentation*

             For more information about GitLab chatops, refer to its
             documentation: https://docs.gitlab.com/ee/ci/chatops/index.html.
          MESSAGE

          message
        end

        def project_info
          <<~MESSAGE
            *Project*

            The GitLab project for this chatops integration can be found at
            #{url_for(@project)}.

          MESSAGE
        end

        def full_commands_message(trigger)
          list = @commands
            .map { |command| "#{trigger} #{command.help_message}" }
            .join("\n")

          <<~MESSAGE
            *Available commands*

            The following commands are available for this chatops integration:

            #{list}

            If available, the `run` command is used for running GitLab CI jobs
            defined in this project's `.gitlab-ci.yml` file. For example, if a
            job called "help" is defined you can run it like so:

            `#{trigger} run help`
          MESSAGE
        end
      end
    end
  end
end

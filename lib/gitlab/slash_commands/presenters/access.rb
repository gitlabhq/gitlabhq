# frozen_string_literal: true

module Gitlab
  module SlashCommands
    module Presenters
      class Access < Presenters::Base
        def access_denied(project)
          ephemeral_response(text: <<~MESSAGE)
            You are not allowed to perform the given chatops command. Most
            likely you do not have access to the GitLab project for this chatops
            integration.

            The GitLab project for this chatops integration can be found at
            #{url_for(project)}.
          MESSAGE
        end

        def generic_access_denied
          ephemeral_response(text: 'You are not allowed to perform the given chatops command.')
        end

        def deactivated
          ephemeral_response(text: <<~MESSAGE)
            You are not allowed to perform the given chatops command since
            your account has been deactivated by your administrator.

            Please log back in from a web browser to reactivate your account at #{Gitlab.config.gitlab.url}
          MESSAGE
        end

        def not_found
          ephemeral_response(text: "404 not found! GitLab couldn't find what you were looking for! :boom:")
        end

        def authorize
          message =
            if resource
              ":wave: Hi there! Before I do anything for you, please [connect your GitLab account](#{resource})."
            else
              ":sweat_smile: Couldn't identify you, nor can I authorize you!"
            end

          ephemeral_response(text: message)
        end
      end
    end
  end
end

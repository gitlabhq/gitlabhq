module Gitlab::ChatCommands::Presenters
  class Access < Gitlab::ChatCommands::Presenters::Base
    def access_denied
      ephemeral_response(text: "Whoops! This action is not allowed. This incident will be [reported](https://xkcd.com/838/).")
    end

    def not_found
      ephemeral_response(text: "404 not found! GitLab couldn't find what you were looking for! :boom:")
    end

    def authorize
      message =
        if @resource
          ":wave: Hi there! Before I do anything for you, please [connect your GitLab account](#{@resource})."
        else
          ":sweat_smile: Couldn't identify you, nor can I autorize you!"
        end

      ephemeral_response(text: message)
    end
  end
end

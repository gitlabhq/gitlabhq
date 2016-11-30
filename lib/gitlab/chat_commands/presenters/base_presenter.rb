module Gitlab::ChatCommands::Presenters
  module BasePresenter
    include Gitlab::Routing.url_helpers

    def access_denied
      ephemeral_response("Whoops! That action is not allowed. This incident will be [reported](https://xkcd.com/838/).")
    end

    def not_found
      ephemeral_response("404 not found! GitLab couldn't find what you were looking for! :boom:")
    end

    def authorize_chat_name(url)
      message = if url
                  ":wave: Hi there! Before I do anything for you, please [connect your GitLab account](#{url})."
                else
                  ":sweat_smile: Couldn't identify you, nor can I autorize you!"
                end

      ephemeral_response(message)
    end

    private

    def header_with_list(header, items)
      message = [header]

      items.each do |item|
        message << "- #{item}"
      end

      message.join("\n")
    end

    def ephemeral_response(message)
      {
        response_type: :ephemeral,
        text: message,
        status: 200
      }
    end

    def in_channel_response(message)
      {
        response_type: :in_channel,
        text: message,
        status: 200
      }
    end

    def url(resource)
      url_for(
        [
          resource.project.namespace.becomes(Namespace),
          resource.project,
          resource
        ]
      )
    end
  end
end

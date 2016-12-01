module Gitlab::ChatCommands::Presenters
  class BasePresenter
    include Gitlab::Routing.url_helpers

    def initialize(resource)
      @resource = resource
    end

    def display_errors
      message = header_with_list("The action was not successful, because:", @resource.errors.full_messages)

      ephemeral_response(text: message)
    end

    def access_denied
      ephemeral_response(text: "Whoops! That action is not allowed. This incident will be [reported](https://xkcd.com/838/).")
    end

    def not_found
      ephemeral_response(text: "404 not found! GitLab couldn't find what you were looking for! :boom:")
    end

    def authorize_chat_name(url)
      message =
        if url
          ":wave: Hi there! Before I do anything for you, please [connect your GitLab account](#{url})."
        else
          ":sweat_smile: Couldn't identify you, nor can I autorize you!"
        end

      ephemeral_response(text: message)
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
        status: 200
      }.merge(message)
    end

    def in_channel_response(message)
      {
        response_type: :in_channel,
        status: 200
      }.merge(message)
    end

    # Convert Markdown to slacks format
    def format(string)
      Slack::Notifier::LinkFormatter.format(string)
    end

    def resource_url
      url_for(
        [
          @resource.project.namespace.becomes(Namespace),
          @resource.project,
          @resource
        ]
      )
    end

  end
end

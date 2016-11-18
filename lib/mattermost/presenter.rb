module Mattermost
  class Presenter
    class << self
      include Gitlab::Routing.url_helpers

      def authorize_chat_name(url)
        message = if url
                    ":wave: Hi there! Before I do anything for you, please [connect your GitLab account](#{url})."
                  else
                    ":sweat_smile: Couldn't identify you, nor can I autorize you!"
                  end

        ephemeral_response(message)
      end

      def help(commands, trigger)
        if commands.zero?
          ephemeral_response("No commands configured")
        else
          message = header_with_list("Available commands", commands)

          ephemeral_response(message)
        end
      end

      def present(resource)
        return not_found unless resource

        if resource.respond_to?(:count)
          if resource.count > 1
            return multiple_resources(resource)
          elsif resource.count == 0
            return not_found
          else
            resource = resource.first
          end
        end

        single_resource(resource)
      end

      def access_denied
        ephemeral_response("Whoops! That action is not allowed. This incident will be [reported](https://xkcd.com/838/).")
      end

      private

      def not_found
        ephemeral_response("404 not found! GitLab couldn't find what your were looking for! :boom:")
      end

      def single_resource(resource)
        return error(resource) if resource.errors.any? || !resource.persisted?

        message = "### #{title(resource)}"
        message << "\n\n#{resource.description}" if resource.description

        in_channel_response(message)
      end

      def multiple_resources(resources)
        resources.map! { |resource| title(resource) }

        message = header_with_list("Multiple results were found:", resources)

        ephemeral_response(message)
      end

      def error(resource)
        message = header_with_list("The action was not succesful, because:", resource.errors.messages)

        ephemeral_response(message)
      end

      def title(resource)
        "[#{resource.to_reference} #{resource.title}](#{url(resource)})"
      end

      def header_with_list(header, items)
        message = [header]

        items.each do |item|
          message << "- #{item}"
        end

        message.join("\n")
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
    end
  end
end

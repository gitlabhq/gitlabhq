module Gitlab
  module ChatCommands
    class Presenter
      include Gitlab::Routing

      def authorize_chat_name(url)
        message = if url
                    ":wave: Hi there! Before I do anything for you, please [connect your GitLab account](#{url})."
                  else
                    ":sweat_smile: Couldn't identify you, nor can I autorize you!"
                  end

        ephemeral_response(message)
      end

      def help(commands, trigger)
        if commands.none?
          ephemeral_response("No commands configured")
        else
          commands.map! { |command| "#{trigger} #{command}" }
          message = header_with_list("Available commands", commands)

          ephemeral_response(message)
        end
      end

      def present(subject)
        return not_found unless subject

        if subject.is_a?(Gitlab::ChatCommands::Result)
          show_result(subject)
        elsif subject.respond_to?(:count)
          if subject.many?
            multiple_resources(subject)
          elsif subject.none?
            not_found
          else
            single_resource(subject)
          end
        else
          single_resource(subject)
        end
      end

      def access_denied
        ephemeral_response("Whoops! That action is not allowed. This incident will be [reported](https://xkcd.com/838/).")
      end

      private

      def show_result(result)
        case result.type
        when :success
          in_channel_response(result.message)
        else
          ephemeral_response(result.message)
        end
      end

      def not_found
        ephemeral_response("404 not found! GitLab couldn't find what you were looking for! :boom:")
      end

      def single_resource(resource)
        return error(resource) if resource.errors.any? || !resource.persisted?

        message = "#{title(resource)}:"
        message << "\n\n#{resource.description}" if resource.try(:description)

        in_channel_response(message)
      end

      def multiple_resources(resources)
        resources.map! { |resource| title(resource) }

        message = header_with_list("Multiple results were found:", resources)

        ephemeral_response(message)
      end

      def error(resource)
        message = header_with_list("The action was not successful, because:", resource.errors.messages)

        ephemeral_response(message)
      end

      def title(resource)
        reference = resource.try(:to_reference) || resource.try(:id)
        title = resource.try(:title) || resource.try(:name)

        "[#{reference} #{title}](#{url(resource)})"
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

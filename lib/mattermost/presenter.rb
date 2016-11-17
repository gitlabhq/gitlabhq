module Mattermost
  class Presenter
    class << self
      include Rails.application.routes.url_helpers

      def authorize_chat_name(url)
        message = "Hi there! We've yet to get acquainted! Please introduce yourself by [connection your GitLab profile](#{url})!"

        ephemeral_response(message)
      end

      def help(messages, command)
        return ephemeral_response("No commands configured") unless messages.count > 1
        message = ["Available commands:"]

        messages.each do |messsage|
          message << "- #{command} #{message}"
        end

        ephemeral_response(message.join("\n"))
      end

      def not_found
        ephemeral_response("404 not found! GitLab couldn't find what your were looking for! :boom:")
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

      private

      def single_resource(resource)
        return error(resource) if resource.errors.any?

        message = "### #{title(resource)}"
        message << "\n\n#{resource.description}" if resource.description

        in_channel_response(message)
      end

      def multiple_resources(resources)
        message = "Multiple results were found:\n"
        message << resources.map { |resource| "- #{title(resource)}" }.join("\n")

        ephemeral_response(message)
      end

      def error(resource)
        message = "The action was not succesfull because:\n"
        message << resource.errors.messages.map { |message| "- #{message}" }.join("\n")

        ephemeral_response(resource.errors.messages.join("\n"))
      end

      def title(resource)
        "[#{resource.to_reference} #{resource.title}](#{url(resource)})"
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
          text: message
        }
      end

      def in_channel_response(message)
        {
          response_type: :in_channel,
          text: message
        }
      end
    end
  end
end

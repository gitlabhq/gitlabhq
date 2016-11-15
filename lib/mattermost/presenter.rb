module Mattermost
  class Presenter
    class << self
      COMMAND_PREFIX = '/gitlab'.freeze

      def authorize_chat_name(params)
        url = ChatNames::RequestService.new(service, params).execute

        {
          response_type: :ephemeral,
          message: "You are not authorized. Click this [link](#{url}) to authorize."
        }
      end

      # TODO figure out how I know which are available or not
      def help_message(commands)
        messages = ["Available commands:"]

        commands.each do |sub_command, attrs|
          messages << "\t#{COMMAND_PREFIX} #{attrs[:help_message]}"
        end

        {
          response_type: :ephemeral,
          text: messages.join("\n")
        }
      end

      def not_found
        {
          response_type: :ephemeral,
          text: "404 not found! GitLab couldn't find what your were looking for! :boom:",
        }
      end
    end

    attr_reader :result

    def initialize(result)
      @result = result
    end

    def present
      if result.respond_to?(:count)
        if result.count > 1
          return respond_collection(result)
        elsif result.count == 0
          return not_found
        else
          result = result.first
        end
      end

      single_resource
    end

    private

    def single_resource
      message = title(resource)
      message << "\n\n#{resource.description}" if resource.description

      {
        response_type: :in_channel,
        text: message
      }
    end

    def multiple_resources(resources)
      message = "Multiple results were found:\n"
      message << resource.map { |resource| "  #{title(resource)}" }.join("\n")

      {
        response_type: :ephemeral,
        text: message
      }
    end

    def title(resource)
      url = url_for([resource.project.namespace.becomes(Namespace), resource.project, resource])
      "### [#{resource.to_reference} #{resource.title}](#{url})"
    end
  end
end

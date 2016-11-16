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

      def help(messages)
        messages = ["Available commands:"]

        messages.each do |messsage|
          messages << "- #{message}"
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
        message = title(resource)
        message << "\n\n#{resource.description}" if resource.description

        {
          response_type: :in_channel,
          text: message
        }
      end

      def multiple_resources(resources)
        message = "Multiple results were found:\n"
        message << resources.map { |resource| "  #{title(resource)}" }.join("\n")

        {
          response_type: :ephemeral,
          text: message
        }
      end

      def title(resource)
        "### [#{resource.to_reference} #{resource.title}](#{url(resource)})"
      end

      def url(resource)
        helper = Rails.application.routes.url_helpers

        case resource
        when Issue
          helper.namespace_project_issue_url(resource.project.namespace.becomes(Namespace), resource.project, resource)
        when MergeRequest
          helper.namespace_project_merge_request_url(resource.project.namespace.becomes(Namespace), resource.project, resource)
        end
      end
    end
  end
end

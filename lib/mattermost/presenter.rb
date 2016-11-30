module Mattermost
  class Presenter
    class << self
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

      private

      def show_result(result)
        case result.type
        when :success
          in_channel_response(result.message)
        else
          ephemeral_response(result.message)
        end
      end

      def single_resource(resource)
        return error(resource) if resource.errors.any? || !resource.persisted?

        message = "### #{title(resource)}"
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
    end
  end
end

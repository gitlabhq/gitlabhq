# frozen_string_literal: true

module Ci
  module Components
    class FetchService
      include Gitlab::Utils::StrongMemoize

      COMPONENT_PATHS = [
        ::Gitlab::Ci::Components::InstancePath
      ].freeze

      def initialize(address:, current_user:)
        @address = address
        @current_user = current_user
      end

      def execute
        unless component_path_class
          return ServiceResponse.error(
            message: "#{error_prefix} the component path is not supported",
            reason: :unsupported_path)
        end

        component_path = component_path_class.new(address: address)

        result = component_path.fetch_content!(current_user: current_user)

        if result&.content
          ServiceResponse.success(payload: {
            content: result.content,
            path: result.path,
            project: component_path.project,
            sha: component_path.sha,
            name: component_path.component_name
          })
        elsif component_path.invalid_usage_for_latest?
          ServiceResponse.error(
            message: "#{error_prefix} The ~latest version reference is not supported for non-catalog resources. " \
                     'Use a tag, branch, or commit SHA instead.',
            reason: :invalid_usage)
        else
          ServiceResponse.error(message: "#{error_prefix} content not found", reason: :content_not_found)
        end
      rescue Gitlab::Access::AccessDeniedError
        if current_user.external? && component_path.project.internal?
          ServiceResponse.error(
            message: "#{error_prefix} project is `Internal`, it cannot be accessed by an External User",
            reason: :not_allowed)
        else
          ServiceResponse.error(
            message: "#{error_prefix} project does not exist or you don't have sufficient permissions",
            reason: :not_allowed)
        end
      end

      private

      attr_reader :current_user, :address

      def component_path_class
        COMPONENT_PATHS.find { |klass| klass.match?(address) }
      end
      strong_memoize_attr :component_path_class

      def error_prefix
        "Component '#{address}' -"
      end
    end
  end
end

# frozen_string_literal: true

# rubocop: disable Gitlab/BoundedContexts -- Custom attributes are a cross-cutting concern for Users, Projects, and Groups
module CustomAttributes
  class DestroyService
    ALLOWED_RESOURCES = [User, Project, Group].freeze

    def initialize(resource, current_user:, key:, params: {})
      @resource = resource
      @current_user = current_user
      @key = key
      @params = params

      validate_resource_type!
    end

    def execute
      return ServiceResponse.error(message: 'You are not authorized to perform this action') unless authorized?

      custom_attribute = resource.custom_attributes.find_by_key(key)

      return ServiceResponse.error(message: 'Custom attribute not found') unless custom_attribute

      custom_attribute.destroy

      ServiceResponse.success(payload: { custom_attribute: custom_attribute })
    end

    private

    attr_reader :resource, :current_user, :key, :params

    def authorized?
      Ability.allowed?(current_user, :delete_custom_attribute, resource)
    end

    def validate_resource_type!
      return if ALLOWED_RESOURCES.any? { |klass| resource.is_a?(klass) }

      raise ArgumentError,
        "Resource type '#{resource.class.name}' is not supported. " \
          "Allowed types: #{ALLOWED_RESOURCES.map(&:name).join(', ')}"
    end
  end
end
# rubocop: enable Gitlab/BoundedContexts

# frozen_string_literal: true

# rubocop: disable Gitlab/BoundedContexts -- Custom attributes are a cross-cutting concern for Users, Projects, and Groups
module CustomAttributes
  class UpsertService
    include BaseServiceUtility

    ALLOWED_RESOURCES = [User, Project, Group].freeze

    def initialize(resource, current_user:, key:, value:)
      @resource = resource
      @current_user = current_user
      @key = key
      @value = value

      validate_resource_type!
    end

    # rubocop: disable CodeReuse/ActiveRecord -- Custom attribute CRUD is simple enough to not need a separate abstraction
    def execute
      return ServiceResponse.error(message: 'unauthorized', reason: :unauthorized) unless authorized?

      custom_attribute = resource.custom_attributes.find_or_initialize_by(key: key)
      custom_attribute.value = value

      if custom_attribute.save
        ServiceResponse.success(payload: { custom_attribute: custom_attribute })
      else
        ServiceResponse.error(message: custom_attribute.errors.full_messages)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    attr_reader :resource, :current_user, :key, :value

    def authorized?
      current_user.can?(:update_custom_attribute, resource)
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

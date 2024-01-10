# frozen_string_literal: true

module ActivityPub
  # Serializer for the `Object` ActivityStreams model.
  # Reference: https://www.w3.org/TR/activitystreams-core/#object
  class ObjectSerializer < ::BaseSerializer
    MissingIdentifierError = Class.new(StandardError)
    MissingTypeError = Class.new(StandardError)

    def represent(resource, opts = {}, entity_class = nil)
      serialized = super(resource, opts, entity_class)
      response = wrap(serialized, opts)

      validate_response(HashWithIndifferentAccess.new(response), opts)
    end

    private

    def wrap(serialized, _opts)
      { :@context => "https://www.w3.org/ns/activitystreams" }.merge(serialized)
    end

    def validate_response(response, _opts)
      unless response[:id].present?
        raise MissingIdentifierError, "The serializer does not provide the mandatory 'id' field."
      end

      unless response[:type].present?
        raise MissingTypeError, "The serializer does not provide the mandatory 'type' field."
      end

      response
    end
  end
end

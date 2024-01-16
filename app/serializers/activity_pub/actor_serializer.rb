# frozen_string_literal: true

module ActivityPub
  # Serializer for the `Actor` ActivityStreams model.
  # Reference: https://www.w3.org/TR/activitystreams-core/#actors
  class ActorSerializer < ObjectSerializer
    MissingOutboxError = Class.new(StandardError)

    def represent(resource, opts = {}, entity_class = nil)
      raise MissingInboxError, 'Please provide an :inbox option for this actor' unless opts[:inbox].present?
      raise MissingOutboxError, 'Please provide an :outbox option for this actor' unless opts[:outbox].present?

      super
    end

    private

    def validate_response(response, _opts)
      unless response[:id].present?
        raise MissingIdentifierError, "The serializer does not provide the mandatory 'id' field."
      end

      unless response[:type].present?
        raise MissingTypeError, "The serializer does not provide the mandatory 'type' field."
      end

      response
    end

    def wrap(serialized, opts)
      parent_value = super(serialized, opts)

      {
        inbox: opts[:inbox],
        outbox: opts[:outbox]
      }.merge(parent_value)
    end
  end
end

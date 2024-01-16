# frozen_string_literal: true

module ActivityPub
  # Serializer for the `Activity` ActivityStreams model.
  # Reference: https://www.w3.org/TR/activitystreams-core/#activities
  class ActivitySerializer < ObjectSerializer
    MissingActorError = Class.new(StandardError)
    MissingObjectError = Class.new(StandardError)
    IntransitiveWithObjectError = Class.new(StandardError)

    private

    def validate_response(serialized, opts)
      response = super(serialized, opts)

      unless response[:actor].present?
        raise MissingActorError, "The serializer does not provide the mandatory 'actor' field."
      end

      if opts[:intransitive] && response[:object].present?
        raise IntransitiveWithObjectError, <<~ERROR
          The serializer does provide both the 'object' field and the :intransitive option.
          Intransitive activities are meant precisely for when no object is available.
          Please remove either of those.
          See https://www.w3.org/TR/activitystreams-vocabulary/#activity-types
        ERROR
      end

      unless opts[:intransitive] || response[:object].present?
        raise MissingObjectError, <<~ERROR
          The serializer does not provide the mandatory 'object' field.
          Pass the :intransitive option to #represent if this is an intransitive activity.
          See https://www.w3.org/TR/activitystreams-vocabulary/#activity-types
        ERROR
      end

      response
    end
  end
end

# frozen_string_literal: true

# An Event object represents a domain event that occurred in a bounded context.
# By publishing events we notify other bounded contexts about something
# that happened, so that they can react to it.
#
# Define new event classes under `app/events/<namespace>/` with a name
# representing something that happened in the past:
#
#   class Projects::ProjectCreatedEvent < Gitlab::EventStore::Event
#     def schema
#       {
#         'type' => 'object',
#         'properties' => {
#           'project_id' => { 'type' => 'integer' }
#         }
#       }
#     end
#   end
#
# To publish it:
#
#   Gitlab::EventStore.publish(
#     Projects::ProjectCreatedEvent.new(data: { project_id: project.id })
#   )
#
module Gitlab
  module EventStore
    class Event
      attr_reader :data

      class << self
        attr_accessor :json_schema_valid
      end

      def initialize(data:)
        validate_schema!
        validate_data!(data)
        @data = data.with_indifferent_access
      end

      def schema
        raise NotImplementedError, 'must specify schema to validate the event'
      end

      private

      def validate_schema!
        if self.class.json_schema_valid.nil?
          self.class.json_schema_valid = JSONSchemer.schema(Event.json_schema).valid?(schema)
        end

        return if self.class.json_schema_valid == true

        raise Gitlab::EventStore::InvalidEvent, "Schema for event #{self.class} is invalid"
      end

      def validate_data!(data)
        unless data.is_a?(Hash)
          raise Gitlab::EventStore::InvalidEvent, "Event data must be a Hash"
        end

        errors = JSONSchemer.schema(schema).validate(data.deep_stringify_keys).map do |error|
          JSONSchemer::Errors.pretty(error)
        end

        unless errors.empty?
          raise Gitlab::EventStore::InvalidEvent, "Data for event #{self.class} does not match the defined schema: #{errors.inspect}"
        end
      end

      def self.json_schema
        @json_schema ||= Gitlab::Json.parse(File.read(File.join(__dir__, 'json_schema_draft07.json')))
      end
    end
  end
end

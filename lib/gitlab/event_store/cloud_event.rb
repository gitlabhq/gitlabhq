# frozen_string_literal: true

module Gitlab
  module EventStore
    class CloudEvent < Event
      extend ::Gitlab::Utils::Override
      include Gitlab::Utils::StrongMemoize
      include Gitlab::ClassAttributes

      UnknownCloudEventTypeError = Class.new(StandardError)
      UnsupportedPayloadError = Class.new(StandardError)

      # Registered at class-load time (single-threaded boot) and only read at
      # runtime, so a plain Hash is safe without synchronization.
      REGISTRY = {} # rubocop:disable Style/MutableConstant -- mutated by .register

      # CloudEvents v1.0 attributes that are not required context attributes
      # (id, source, spec_version, type). The CloudEvents spec calls these
      # "Optional & Extension Attributes"; in the protobuf representation
      # they live in the `attributes` map rather than as dedicated fields.
      ATTRIBUTES = %i[
        datacontenttype
        dataschema
        gitlab_organization_id
        gitlab_user_id
        gitlab_user_username
        subject
        time
      ].freeze

      class << self
        def event_category(value)
          set_class_attribute(:event_category, value)
        end

        def event_type(value)
          set_class_attribute(:event_type, value)
        end

        def get_event_category
          get_class_attribute(:event_category) || raise(NotImplementedError)
        end

        def get_event_type
          get_class_attribute(:event_type) || raise(NotImplementedError)
        end

        def build_cloud_event(source:, subject:, current_user:, organization:, event_data: {})
          new(
            data: {
              specversion: '1.0',
              type: "com.gitlab.#{get_event_category}.#{get_event_type}",
              dataschema: "https://gitlab.com/schemas/#{get_event_category}/#{get_event_type}/v1.0",
              id: SecureRandom.uuid,
              datacontenttype: 'application/json',
              time: Time.current.iso8601,
              source: source,
              subject: subject,
              gitlab_user_id: current_user.id,
              gitlab_user_username: current_user.username,
              gitlab_organization_id: organization.id,
              data: event_data
            }
          )
        end

        def register(type, klass)
          raise ArgumentError, "type must be a String, got #{type.class}" unless type.is_a?(String)

          unless klass.is_a?(Class) && klass < Gitlab::EventStore::CloudEvent
            raise ArgumentError, "klass must be a Gitlab::EventStore::CloudEvent subclass, got #{klass.inspect}"
          end

          REGISTRY[type] = klass
        end

        def lookup(type)
          REGISTRY[type]
        end

        # Inverse of #to_proto. The matching subclass must already be registered,
        # which means production callers must reference the event classes before
        # calling from_proto (Rails autoloading won't trigger registration on its own).
        #
        # An incomplete proto (e.g. missing a required attribute) surfaces as
        # Gitlab::EventStore::InvalidEvent from the constructor's schema validation.
        def from_proto(proto)
          klass = lookup(proto.type)

          unless klass
            raise UnknownCloudEventTypeError, "no registered class for CloudEvent type: #{proto.type.inspect}"
          end

          klass.new(data: build_data(proto))
        end

        private

        def build_data(proto)
          # Merge attributes first so the explicit spec fields win: a malformed
          # proto must not override them via its attributes map.
          unwrap_attributes(proto.attributes).merge(
            id: proto.id,
            source: proto.source,
            specversion: proto.spec_version,
            type: proto.type,
            data: decode_payload(proto)
          )
        end

        def unwrap_attributes(attributes)
          # Iterate the Map directly; #to_h would recursively convert each value
          # into a Hash, losing the #attr oneof accessor used below.
          attributes.each_with_object({}) do |(key, value), unwrapped|
            unwrapped[key.to_sym] = unwrap_attribute_value(value)
          end
        end

        def unwrap_attribute_value(attribute_value)
          # Only the variants #to_proto produces are supported.
          case attribute_value.attr
          when :ce_string then attribute_value.ce_string
          when :ce_integer then attribute_value.ce_integer
          else
            raise UnsupportedPayloadError, "unsupported attribute variant: #{attribute_value.attr.inspect}"
          end
        end

        def decode_payload(proto)
          case proto.data
          when :text_data
            proto.text_data.present? ? ::Gitlab::Json.safe_parse(proto.text_data) : {}
          when :binary_data, :proto_data
            raise UnsupportedPayloadError, "only text_data is supported in v1, got #{proto.data}"
          else
            {} # payload oneof unset: a legitimately empty event
          end
        end
      end

      def current_user
        User.find_by_id(data[:gitlab_user_id])
      end
      strong_memoize_attr :current_user

      def id
        data[:id]
      end
      strong_memoize_attr :id

      def organization
        ::Organizations::Organization.find_by_id(data[:gitlab_organization_id])
      end
      strong_memoize_attr :organization

      def event_data
        data.fetch(:data).deep_symbolize_keys
      end

      # Converts this event into its protobuf wire representation
      # (Gitlab::Agent::Event::CloudEvent), suitable for publishing via
      # Gitlab::Kas::Client#publish_events.
      #
      # The CloudEvents v1.0 protobuf format keeps the required spec
      # attributes (id, source, spec_version, type) as explicit fields
      # and stores all other spec and extension attributes in an
      # `attributes` map. The event payload (`data[:data]`) is
      # JSON-encoded into `text_data`.
      def to_proto
        Gitlab::Agent::Event::CloudEvent.new(
          id: data[:id],
          source: data[:source],
          spec_version: data[:specversion],
          type: data[:type],
          attributes: attributes,
          text_data: event_data.to_json
        )
      end

      def event_category
        self.class.get_event_category
      end

      def event_type
        self.class.get_event_type
      end

      def schema
        required_fields = %w[specversion type source id time datacontenttype dataschema subject data
          gitlab_user_id gitlab_user_username gitlab_organization_id]

        {
          'type' => 'object',
          'properties' => {
            'specversion' => { 'type' => 'string' },
            'type' => { 'type' => 'string' },
            'source' => { 'type' => 'string' },
            'id' => { 'type' => 'string' },
            'gitlab_user_id' => { 'type' => 'number' },
            'gitlab_user_username' => { 'type' => 'string' },
            'gitlab_organization_id' => { 'type' => 'number' },
            'time' => { 'type' => 'string', 'format' => 'date-time' },
            'datacontenttype' => { 'type' => 'string' },
            'dataschema' => { 'type' => 'string', 'format' => 'uri' },
            'subject' => { 'type' => 'string' },
            'data' => { 'type' => 'object' } # This is validated in the data_schema
          },
          'required' => required_fields
        }
      end

      # This is to be overridden by CloudEvent classes.
      # It's meant for the `data` attribute of the CloudEvent spec
      def data_schema
        raise NotImplementedError
      end

      private

      def validate_data!(data)
        super
        validate_event_specific_data!(data.with_indifferent_access.fetch(:data))
      end
      override :validate_data!

      def validate_event_specific_data!(data)
        validate_data_against_schema!(data, data_schema)
      end

      def attributes
        ATTRIBUTES.each_with_object({}) do |key, attrs|
          attrs[key.to_s] = build_attribute_value(data[key])
        end
      end

      def build_attribute_value(value)
        case value
        when Integer
          Gitlab::Agent::Event::CloudEvent::CloudEventAttributeValue.new(ce_integer: value)
        else
          Gitlab::Agent::Event::CloudEvent::CloudEventAttributeValue.new(ce_string: value.to_s)
        end
      end
    end
  end
end

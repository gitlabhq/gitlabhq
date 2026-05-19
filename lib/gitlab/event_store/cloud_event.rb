# frozen_string_literal: true

module Gitlab
  module EventStore
    class CloudEvent < Event
      extend ::Gitlab::Utils::Override
      include Gitlab::Utils::StrongMemoize
      include Gitlab::ClassAttributes

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
        validate_event_specific_data!(data.fetch(:data))
      end
      override :validate_data!

      def validate_event_specific_data!(data)
        validate_data_against_schema!(data, data_schema)
      end
    end
  end
end

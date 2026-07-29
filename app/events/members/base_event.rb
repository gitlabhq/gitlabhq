# frozen_string_literal: true

module Members
  class BaseEvent < ::Gitlab::EventStore::CloudEvent
    event_category :members

    class << self
      protected

      def build_for_member_source(source:, current_user:, extra_event_data: {})
        build_cloud_event(
          source: "#{source.class.name.downcase.pluralize}/#{source.id}",
          subject: "members/#{source.class.name.downcase}/#{source.id}",
          current_user: current_user,
          organization: source.organization,
          event_data: member_source_event_data(source).merge(extra_event_data)
        )
      end

      private

      def member_source_event_data(source)
        {
          source_id: source.id,
          source_type: source.class.name
        }
      end
    end

    def data_schema
      {
        'type' => 'object',
        'properties' => base_properties.merge(additional_properties),
        'required' => base_required + additional_required
      }
    end

    private

    def base_properties
      {
        'source_id' => { 'type' => 'integer' },
        'source_type' => { 'type' => 'string' }
      }
    end

    def base_required
      %w[source_id source_type]
    end

    # Override in subclasses to add event specific schema properties
    def additional_properties
      {}
    end

    # Override in subclasses to add event specific required fields
    def additional_required
      []
    end
  end
end

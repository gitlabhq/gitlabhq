# frozen_string_literal: true

module Integrations
  class EventEntity < Grape::Entity
    include RequestAwareEntity

    expose :title do |event|
      IntegrationsHelper.integration_event_title(event)
    end

    expose :event_field_name, as: :name

    expose :value do |event|
      integration[event_field_name]
    end

    expose :description do |event|
      IntegrationsHelper.integration_event_description(integration, event)
    end

    expose :field, if: ->(_, _) { integration.try(:configurable_channels?) } do
      expose :name do |event|
        integration.event_channel_name(event)
      end
      expose :value do |event|
        integration.event_channel_value(event)
      end
      expose :placeholder do |_event|
        integration.default_channel_placeholder
      end
    end

    private

    alias_method :event, :object

    def event_field_name
      IntegrationsHelper.integration_event_field_name(event)
    end

    def integration
      request.integration
    end
  end
end

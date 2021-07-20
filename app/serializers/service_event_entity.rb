# frozen_string_literal: true

class ServiceEventEntity < Grape::Entity
  include RequestAwareEntity

  expose :title do |event|
    event
  end

  expose :event_field_name, as: :name

  expose :value do |event|
    integration[event_field_name]
  end

  expose :description do |event|
    IntegrationsHelper.integration_event_description(integration, event)
  end

  expose :field, if: -> (_, _) { event_field } do
    expose :name do |event|
      event_field[:name]
    end
    expose :value do |event|
      integration.public_send(event_field[:name]) # rubocop:disable GitlabSecurity/PublicSend
    end
  end

  private

  alias_method :event, :object

  def event_field_name
    IntegrationsHelper.integration_event_field_name(event)
  end

  def event_field
    @event_field ||= integration.event_field(event)
  end

  def integration
    request.service
  end
end

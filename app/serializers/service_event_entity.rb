# frozen_string_literal: true

class ServiceEventEntity < Grape::Entity
  include RequestAwareEntity

  expose :title do |event|
    event
  end

  expose :event_field_name, as: :name

  expose :value do |event|
    service[event_field_name]
  end

  expose :description do |event|
    service.class.event_description(event)
  end

  expose :field, if: -> (_, _) { event_field } do
    expose :name do |event|
      event_field[:name]
    end
    expose :value do |event|
      service.public_send(event_field[:name]) # rubocop:disable GitlabSecurity/PublicSend
    end
  end

  private

  alias_method :event, :object

  def event_field_name
    ServicesHelper.service_event_field_name(event)
  end

  def event_field
    @event_field ||= service.event_field(event)
  end

  def service
    request.service
  end
end

module ServicesHelper
  prepend EE::ServicesHelper

  def service_event_field_name(event)
    event = event.pluralize if %w[merge_request issue confidential_issue].include?(event)
    "#{event}_events"
  end

  def service_save_button(service)
    button_tag(class: 'btn btn-save', type: 'submit', disabled: service.deprecated?) do
      icon('spinner spin', class: 'hidden js-btn-spinner') +
        content_tag(:span, 'Save changes', class: 'js-btn-label')
    end
  end

  def disable_fields_service?(service)
    !current_controller?("admin/services") && service.deprecated?
  end

  extend self
end

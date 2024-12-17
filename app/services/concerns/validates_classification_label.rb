# frozen_string_literal: true

module ValidatesClassificationLabel
  def validate_classification_label_param!(record, attribute_name)
    return unless ::Gitlab::ExternalAuthorization.enabled?
    return unless classification_label_change?(record, attribute_name)

    new_label = params[attribute_name].presence
    new_label ||= ::Gitlab::CurrentSettings.current_application_settings
                    .external_authorization_service_default_label

    unless ::Gitlab::ExternalAuthorization.access_allowed?(current_user, new_label)
      reason = rejection_reason_for_label(new_label)
      message = s_('ClassificationLabelUnavailable|is unavailable: %{reason}') % { reason: reason }
      record.errors.add(attribute_name, message)
    end

    params[attribute_name] = new_label
  end

  def rejection_reason_for_label(label)
    reason_from_service = ::Gitlab::ExternalAuthorization.rejection_reason(current_user, label).presence
    reason_from_service || (_("Access to '%{classification_label}' not allowed") % { classification_label: label })
  end

  def classification_label_change?(record, attribute_name)
    params.key?(attribute_name) || record.new_record?
  end
end

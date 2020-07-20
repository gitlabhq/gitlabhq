# frozen_string_literal: true

module IncidentManagement
  class CreateIncidentLabelService < BaseService
    LABEL_PROPERTIES = {
      title: 'incident',
      color: '#CC0033',
      description: <<~DESCRIPTION.chomp
        Denotes a disruption to IT services and \
        the associated issues require immediate attention
      DESCRIPTION
    }.freeze

    def execute
      label = Labels::FindOrCreateService
        .new(current_user, project, **LABEL_PROPERTIES)
        .execute

      if label.invalid?
        log_invalid_label_info(label)
        return ServiceResponse.error(payload: { label: label }, message: full_error_message(label))
      end

      ServiceResponse.success(payload: { label: label })
    end

    private

    def log_invalid_label_info(label)
      log_info <<~TEXT.chomp
        Cannot create incident label "#{label.title}" \
        for "#{label.project.full_name}": #{full_error_message(label)}.
      TEXT
    end

    def full_error_message(label)
      label.errors.full_messages.to_sentence
    end
  end
end

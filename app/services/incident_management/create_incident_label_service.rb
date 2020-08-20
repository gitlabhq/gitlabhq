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
        .execute(skip_authorization: true)

      ServiceResponse.success(payload: { label: label })
    end
  end
end

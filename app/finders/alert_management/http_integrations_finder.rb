# frozen_string_literal: true

module AlertManagement
  class HttpIntegrationsFinder
    def initialize(project, params)
      @project = project
      @params = params
    end

    def execute
      @collection = project.alert_management_http_integrations

      filter_by_availability
      filter_by_endpoint_identifier
      filter_by_active

      collection
    end

    private

    attr_reader :project, :params, :collection

    def filter_by_availability
      return if multiple_alert_http_integrations?

      first_id = project.alert_management_http_integrations
                        .ordered_by_id
                        .select(:id)
                        .limit(1)

      @collection = collection.id_in(first_id)
    end

    def filter_by_endpoint_identifier
      return unless params[:endpoint_identifier]

      @collection = collection.for_endpoint_identifier(params[:endpoint_identifier])
    end

    def filter_by_active
      return unless params[:active]

      @collection = collection.active
    end

    # Overridden in EE
    def multiple_alert_http_integrations?
      false
    end
  end
end

::AlertManagement::HttpIntegrationsFinder.prepend_mod_with('AlertManagement::HttpIntegrationsFinder')

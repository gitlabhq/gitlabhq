# frozen_string_literal: true

module AlertManagement
  class HttpIntegrationsFinder
    TYPE_IDENTIFIERS = ::AlertManagement::HttpIntegration.type_identifiers

    def initialize(project, params = {})
      @project = project
      @params = params
    end

    def execute
      @collection = project.alert_management_http_integrations

      filter_by_availability
      filter_by_endpoint_identifier
      filter_by_active
      filter_by_type

      collection
    end

    private

    attr_reader :project, :params, :collection

    # Overridden in EE
    def filter_by_availability
      # Re-find by id so subsequent filters don't expose unavailable records
      @collection = collection.id_in(collection
        .select('DISTINCT ON (type_identifier) id')
        .ordered_by_type_and_id
        .limit(TYPE_IDENTIFIERS.length))
    end

    def filter_by_endpoint_identifier
      return unless params[:endpoint_identifier]

      @collection = collection.for_endpoint_identifier(params[:endpoint_identifier])
    end

    def filter_by_active
      return unless params[:active]

      @collection = collection.active
    end

    def filter_by_type
      return unless params[:type_identifier]
      return unless TYPE_IDENTIFIERS.include?(params[:type_identifier])

      @collection = collection.for_type(params[:type_identifier])
    end
  end
end

::AlertManagement::HttpIntegrationsFinder.prepend_mod_with('AlertManagement::HttpIntegrationsFinder')

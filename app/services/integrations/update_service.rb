# frozen_string_literal: true

module Integrations
  class UpdateService
    include ::Services::ReturnServiceResponses
    include Gitlab::Utils::StrongMemoize

    def initialize(current_user:, integration:, attributes:)
      @current_user = current_user
      @integration = integration
      @attributes = attributes
    end

    def execute
      return error('Integration not found.', :not_found) unless integration

      if handle_inherited_settings?
        handle_inherited_settings
      else
        handle_default_settings
      end
    end

    private

    attr_reader :current_user, :integration, :attributes

    def handle_inherited_settings?
      if attributes.key?(:use_inherited_settings)
        Gitlab::Utils.to_boolean(attributes[:use_inherited_settings], default: false)
      else
        integration.inherit_from_id?
      end
    end

    def default_integration
      ::Integration.default_integration(integration.type, integration.parent)
    end
    strong_memoize_attr :default_integration

    def handle_inherited_settings
      return error('Default integration not found.', :not_found) unless default_integration

      integration.inherit_from_id = default_integration.id

      unless integration.save(context: :manual_change)
        return error("Failed to update integration. #{integration.errors.messages}", :bad_request)
      end

      if integration.project_level?
        ::Integrations::Propagation::BulkUpdateService.new(default_integration, [integration]).execute
      end

      success(integration)
    end

    def handle_default_settings
      attributes.delete(:use_inherited_settings)
      integration.inherit_from_id = nil
      integration.attributes = attributes

      if integration.save(context: :manual_change)
        success(integration)
      else
        error("Failed to update integration. #{integration.errors.messages}", :bad_request)
      end
    end
  end
end

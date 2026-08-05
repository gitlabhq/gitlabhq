# frozen_string_literal: true

module Observability
  module AccessRequestActions
    extend ActiveSupport::Concern
    include Gitlab::InternalEventsTracking

    def create
      namespace = observability_namespace

      if namespace.observability_group_o11y_setting.present?
        flash[:alert] = already_enabled_message
      else
        result = build_access_request_service(namespace).execute

        if result.success?
          flash[:success] = success_message

          track_internal_event(
            'create_observability_access_request',
            user: current_user,
            namespace: namespace,
            additional_properties: { label: observability_context_label }
          )
        else
          flash[:alert] = result.message
        end
      end

      redirect_to setup_redirect_path
    end

    private

    # Subclasses must define:
    #   observability_namespace    - the Group or personal Namespace
    #   setup_redirect_path       - where to redirect after create
    #   already_enabled_message   - flash text when already enabled
    #   success_message           - flash text on success
    #   build_access_request_service(namespace) - returns the service instance
    #   observability_context_label - "group" or "project", used for tracking
    def observability_namespace
      raise NotImplementedError
    end

    def setup_redirect_path
      raise NotImplementedError
    end

    def already_enabled_message
      raise NotImplementedError
    end

    def success_message
      raise NotImplementedError
    end

    def build_access_request_service(_namespace)
      raise NotImplementedError
    end

    def observability_context_label
      raise NotImplementedError
    end
  end
end
